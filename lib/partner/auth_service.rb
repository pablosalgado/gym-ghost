# frozen_string_literal: true

require "httparty"
require "json"

module Partner
  # Authenticates a GymMember against the downstream gym partner API and
  # persists the returned access/refresh tokens as a PartnerToken.
  #
  # Branch configuration (API base URL, branch id, branch code) is sourced
  # from environment variables for now; it will move to the database later.
  class AuthService
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

    LOGIN_PATH = "/api/v1/auth/login"

    def initialize(gym_member:)
      @gym_member = gym_member
    end

    # Performs the partner login and stores the returned tokens.
    # Returns the persisted PartnerToken on success.
    # Raises Partner::AuthenticationError on any authentication failure.
    def login
      response = request_login
      raise AuthenticationError, error_detail(response) unless response.success?

      payload = parse_payload(response)
      access_token = payload["access_token"].to_s
      refresh_token = payload["refresh_token"].to_s

      raise AuthenticationError, "Missing access token in partner response" if access_token.empty?
      raise AuthenticationError, "Missing refresh token in partner response" if refresh_token.empty?

      gym_member.partner_tokens.create!(
        access_token:,
        refresh_token:,
        token_expires_at: decode_jwt_expiry(access_token)
      )
    end

    private

    attr_reader :gym_member

    def request_login
      self.class.post(
        "#{ENV.fetch("PARTNER_API_BASE_URL")}#{LOGIN_PATH}",
        body: login_body.to_json,
        headers: {
          "Referer" => ENV.fetch("TEST_PARTNER_AUTH_REFERER"),
          "Origin"  => ENV.fetch("TEST_PARTNER_AUTH_ORIGIN")
        }
      )
    end

    def login_body
      {
        email: gym_member.email,
        password: gym_member.password,
        partner_data: {
          partner_name: ENV.fetch("TEST_PARTNER_AUTH_PARTNER_NAME"),
          branch_id: ENV.fetch("TEST_PARTNER_AUTH_BRANCH_ID").to_i,
          branch_name: ENV.fetch("TEST_PARTNER_AUTH_BRANCH_NAME"),
          token_branch: ENV.fetch("TEST_PARTNER_AUTH_TOKEN_BRANCH"),
          country_code: ENV.fetch("TEST_PARTNER_AUTH_COUNTRY_CODE")
        }
      }
    end

    def parse_payload(response)
      parsed = response.parsed_response
      raise AuthenticationError, "Malformed partner response" unless parsed.is_a?(Hash)

      parsed
    rescue HTTParty::ParseError => e
      raise AuthenticationError, "Malformed partner response: #{e.message}"
    end

    def error_detail(response)
      message =
        begin
          parsed = response.parsed_response
          parsed.is_a?(Hash) ? (parsed["error"] || parsed["message"]) : nil
        rescue StandardError
          nil
        end

      message || "Partner authentication failed (HTTP #{response.code})"
    end

    # Decodes the `exp` claim from the access JWT without adding a JWT gem
    # dependency. Instants are stored as UTC per the date-time convention.
    def decode_jwt_expiry(jwt)
      payload_segment = jwt.split(".").second
      raise AuthenticationError, "Malformed JWT access token" unless payload_segment

      decoded = Base64.urlsafe_decode64(payload_segment)
      exp = JSON.parse(decoded)["exp"]
      raise AuthenticationError, "JWT missing exp claim" unless exp

      Time.at(exp).utc
    rescue ArgumentError, JSON::ParserError => e
      raise AuthenticationError, "Malformed JWT access token: #{e.message}"
    end
  end
end
