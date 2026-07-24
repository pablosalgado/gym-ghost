# frozen_string_literal: true

require "httparty"
require "json"

module Partner
  # Calls the downstream gym partner API to book a schedule entry for a
  # gym member.  Pure API wrapper — does not create or update BookingRequest
  # records and does not handle token refresh.
  class BookingService
    include HTTParty

    format :json
    headers "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:152.0) Gecko/20100101 Firefox/152.0",
            "Accept"          => "application/json, text/plain, */*",
            "Accept-Language" => "en-US,en;q=0.9",
            "Accept-Encoding" => "gzip, deflate, br, zstd",
            "X-Client-Origin" => "WEB",
            "Content-Type"    => "application/json",
            "Connection"      => "keep-alive",
            "Sec-Fetch-Dest"  => "",
            "Sec-Fetch-Mode"  => "cors",
            "Sec-Fetch-Site"  => "cross-site"

    BOOKING_PATH = "/api/v1/activities/booking"

    def initialize(gym_member:)
      @gym_member = gym_member
    end

    # Books the given schedule entry for the gym member through the partner API.
    #
    # schedule_entry — a ScheduleEntry record with partner_activity_id and
    #                   activ_config_id set
    #
    # Returns { confirmation_id:, spot_number: } on success.
    # Raises Partner::BookingError on any failure.
    def book(schedule_entry:)
      response = request_booking(schedule_entry)
      payload = parse_payload(response)

      unless response.success? && payload["status"] == "OK"
        raise BookingError, error_detail(response, payload)
      end

      data = payload["data"] || {}
      {
        confirmation_id: data["_id"].to_s,
        spot_number:     data["spot_number"].to_s
      }
    end

    private

    attr_reader :gym_member

    def access_token
      token = gym_member.partner_tokens.valid_tokens.order(created_at: :desc).first
      raise BookingError, "No valid partner token available" unless token

      token.access_token
    end

    def request_booking(schedule_entry)
      self.class.post(
        "#{ENV.fetch("PARTNER_API_BASE_URL")}#{BOOKING_PATH}",
        body:    book_body(schedule_entry).to_json,
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Origin"        => ENV.fetch("PARTNER_AUTH_ORIGIN"),
          "Referer"       => ENV.fetch("PARTNER_AUTH_REFERER")
        }
      )
    end

    def book_body(schedule_entry)
      {
        activity_id:    schedule_entry.partner_activity_id,
        activ_config_id: schedule_entry.activ_config_id,
        activity_date:  schedule_entry.date.iso8601,
        token_branch:   schedule_entry.facility.evo_token,
        activity_start: schedule_entry.start_time.utc.iso8601,
        timezone:       "America/Bogota",
        activity_name:  schedule_entry.class_type.name,
        capacity:       20,
        branch_name:    schedule_entry.facility.name,
        branch_id:      schedule_entry.facility.external_id,
        partner_name:   "EVO",
        country_code:   "CO",
        booking_origin: "WEB"
      }
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
          first_error = payload["errors"].first
          return first_error["displayable_message"] if first_error["displayable_message"].present?
          return first_error["description"] if first_error["description"].present?
        end

        return payload["error"] if payload["error"].present?
        return payload["message"] if payload["message"].present?
      end

      "Partner booking failed (HTTP #{response.code})"
    end
  end
end
