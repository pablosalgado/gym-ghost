# frozen_string_literal: true

require "httparty"
require "json"

module Partner
  # Fetches facility/branch data from the downstream gym partner API
  # and upserts City and Facility records.
  class FacilitiesService
    include HTTParty

    format :json
    headers "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:152.0) Gecko/20100101 Firefox/152.0",
            "Accept"          => "*/*",
            "Accept-Language" => "en-US,en;q=0.9",
            "Accept-Encoding" => "gzip, deflate, br, zstd",
            "Content-Type"    => "application/json",
            "Connection"      => "keep-alive",
            "Sec-Fetch-Dest"  => "empty",
            "Sec-Fetch-Mode"  => "cors",
            "Sec-Fetch-Site"  => "cross-site"

    BRANCHES_PATH = "/v1/branches"

    def initialize; end

    def sync
      response = request_branches
      payload = parse_payload(response)

      raise FacilitiesSyncError, error_detail(response, payload) unless response.success?

      result = payload["result"]
      raise FacilitiesSyncError, "Missing result array in partner response" unless result.is_a?(Array)

      result.each_with_object([]) do |row, facilities|
        next if row["city_name"].blank? || row["id"].blank?

        city = City.find_or_create_by!(city_name: row["city_name"])

        facility = Facility.find_or_create_by!(external_id: row["id"]) do |f|
          f.city = city
        end
        facility.update!(
          name: row["name"],
          evo_token: row["evo_token"],
          display_name: row["display_name"],
          city: city
        )

        facilities << facility
      end
    end

    private

    def request_branches
      self.class.get(
        "#{ENV.fetch("PARTNER_BRANCHES_API_BASE_URL")}#{BRANCHES_PATH}",
        query: query_params
      )
    end

    def query_params
      {
        country_code: "CO",
        is_deleted: 0,
        brand: ENV.fetch("PARTNER_BRANCHES_BRAND"),
        show_modalities: false
      }
    end

    def parse_payload(response)
      parsed = response.parsed_response
      raise FacilitiesSyncError, "Malformed partner response" unless parsed.is_a?(Hash)

      parsed
    end

    def error_detail(response, payload = nil)
      payload ||= begin
        parsed = response.parsed_response
        parsed.is_a?(Hash) ? parsed : nil
      rescue StandardError
        nil
      end

      if payload
        if payload["errors"].is_a?(Array) && payload["errors"].any?
          return payload["errors"].join(", ")
        end

        return payload["error"] if payload["error"].present?
        return payload["message"] if payload["message"].present?
      end

      "Partner facilities sync failed (HTTP #{response.code})"
    end
  end
end
