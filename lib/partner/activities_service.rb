# frozen_string_literal: true

require "httparty"
require "json"

module Partner
  # Fetches gym activity schedules from the downstream partner API
  # and upserts Activity and ScheduleEntry records.
  class ActivitiesService
    include HTTParty

    format :json
    headers "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:152.0) Gecko/20100101 Firefox/152.0",
            "Accept"          => "application/json, text/plain, */*",
            "Accept-Language" => "en-US,en;q=0.9",
            "Accept-Encoding" => "gzip, deflate, br, zstd",
            "X-Client-Origin" => "WEB",
            "Connection"      => "keep-alive",
            "Sec-Fetch-Dest"  => "",
            "Sec-Fetch-Mode"  => "cors",
            "Sec-Fetch-Site"  => "cross-site"

    ACTIVITIES_PATH = "/api/v1/activities/generic"

    def initialize; end

    # Fetches activities for the given facility and date.
    #
    # facility - a Facility record whose evo_token is sent as token_branch
    # date     - a Date object or a String in YYYY-MM-DD format
    #
    # Returns an array of ScheduleEntry records.
    # Raises Partner::ActivitiesError on any failure.
    def fetch(facility:, date:)
      response = request_activities(facility, date)
      payload = parse_payload(response)

      raise ActivitiesError, error_detail(response, payload) unless response.success?
      raise ActivitiesError, error_detail(response, payload) if payload["status"] == "ERROR"

      data = payload["data"]
      raise ActivitiesError, "Missing data array in partner response" unless data.is_a?(Array)

      data.each_with_object([]) do |item, entries|
        next if item["activity_name"].blank?

        activity = Activity.find_or_create_by!(name: item["activity_name"])

        facility_record = Facility.find_by(external_id: item["branch_id"])
        next if facility_record.nil?

        start_time = item["start_time"]
        entry_date = item["date"] || date
        entry_date = Date.parse(entry_date.to_s) if entry_date.is_a?(String)

        entry = ScheduleEntry.find_or_create_by!(
          facility: facility_record,
          activity: activity,
          start_time: start_time
        ) do |e|
          e.date = entry_date
        end

        entries << entry
      end
    end

    private

    def request_activities(facility, date)
      activities_date = date.is_a?(String) ? date : date.iso8601

      self.class.get(
        "#{ENV.fetch("PARTNER_API_BASE_URL")}#{ACTIVITIES_PATH}",
        query: {
          timezone: "America/Bogota",
          token_branch: facility.evo_token,
          activities_date: activities_date,
          partner_name: "EVO",
          show_full_week: true
        },
        headers: {
          "Authorization" => ENV.fetch("PARTNER_ACTIVITIES_TOKEN"),
          "Origin"        => ENV.fetch("PARTNER_AUTH_ORIGIN"),
          "Referer"       => ENV.fetch("PARTNER_AUTH_REFERER")
        }
      )
    end

    def parse_payload(response)
      parsed = response.parsed_response
      raise ActivitiesError, "Malformed partner response" unless parsed.is_a?(Hash)

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

      "Partner activities fetch failed (HTTP #{response.code})"
    end
  end
end
