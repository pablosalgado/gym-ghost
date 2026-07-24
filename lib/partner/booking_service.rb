# frozen_string_literal: true

require "httparty"
require "json"

module Partner
  # Books a gym session on behalf of a GymMember through the downstream
  # partner booking API. Returns the partner confirmation details on success.
  #
  # Token management: uses the member's latest valid PartnerToken; if none
  # exists or the token is expired, re-authenticates via AuthService.
  class BookingService
    include HTTParty

    format :json
    headers "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:152.0) Gecko/20100101 Firefox/152.0",
            "Accept"          => "application/json, text/plain, */*",
            "Accept-Language" => "en-US,en;q=0.9",
            "Accept-Encoding" => "gzip, deflate, br, zstd",
            "Content-Type"    => "application/json",
            "Connection"      => "keep-alive",
            "Sec-Fetch-Dest"  => "empty",
            "Sec-Fetch-Mode"  => "cors",
            "Sec-Fetch-Site"  => "cross-site"

    BOOKING_PATH = "/api/v1/activities/booking"
    TIMEZONE      = "America/Bogota"
    CAPACITY      = 20
    PARTNER_NAME  = "EVO"
    COUNTRY_CODE  = "CO"
    BOOKING_ORIGIN = "WEB"

    def initialize(schedule_entry:, gym_member:)
      @schedule_entry = schedule_entry
      @gym_member = gym_member
    end

    # Posts a booking request to the partner API.
    #
    # Returns { confirmation_id: <_id>, spot_number: <spot_number> } on success.
    # Raises Partner::BookingError on any failure.
    def book
      response = request_booking
      payload = parse_payload(response)

      raise BookingError, error_detail(response, payload) unless response.success?
      raise BookingError, error_detail(response, payload) unless payload["status"] == "OK"

      data = payload["data"] || {}
      confirmation_id = data["_id"].to_s
      spot_number = data["spot_number"]

      raise BookingError, "Missing confirmation ID in partner response" if confirmation_id.empty?

      { confirmation_id: confirmation_id, spot_number: spot_number }
    end

    private

    attr_reader :schedule_entry, :gym_member

    def request_booking
      self.class.post(
        "#{ENV.fetch("PARTNER_API_BASE_URL")}#{BOOKING_PATH}",
        body: booking_body.to_json,
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Origin"        => ENV.fetch("PARTNER_AUTH_ORIGIN"),
          "Referer"       => ENV.fetch("PARTNER_AUTH_REFERER")
        }
      )
    end

    def booking_body
      facility = schedule_entry.facility

      {
        activity_id:     schedule_entry.partner_activity_id,
        activ_config_id: schedule_entry.activ_config_id,
        activity_date:   schedule_entry.date.iso8601,
        token_branch:    facility.evo_token,
        activity_start:  schedule_entry.start_time.iso8601,
        timezone:        TIMEZONE,
        activity_name:   schedule_entry.class_type.name,
        capacity:        CAPACITY,
        branch_name:     facility.name,
        branch_id:       facility.external_id,
        partner_name:    PARTNER_NAME,
        country_code:    COUNTRY_CODE,
        booking_origin:  BOOKING_ORIGIN
      }
    end

    def access_token
      token = gym_member.partner_tokens.valid_tokens.order(created_at: :desc).first
      token ||= Partner::AuthService.new(gym_member:).login
      token.access_token
    end

    def parse_payload(response)
      parsed = response.parsed_response
      raise BookingError, "Malformed partner response" unless parsed.is_a?(Hash)

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
          first = payload["errors"].first
          return first["displayable_message"].presence || first["description"].presence ||
                 payload["errors"].join(", ")
        end

        return payload["error"] if payload["error"].present?
        return payload["message"] if payload["message"].present?
      end

      "Partner booking failed (HTTP #{response.code})"
    end
  end
end
