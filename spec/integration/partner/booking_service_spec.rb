require "rails_helper"

RSpec.describe "Partner::BookingService", integration: true do
  before do
    skip "Set PARTNER_API_BASE_URL, PARTNER_ACTIVITIES_TOKEN, " \
         "PARTNER_AUTH_ORIGIN, PARTNER_AUTH_REFERER, " \
         "TEST_PARTNER_AUTH_EMAIL, TEST_PARTNER_AUTH_PASSWORD, " \
         "and TEST_BRANCH_TOKEN to run integration tests for BookingService" unless
      ENV["PARTNER_API_BASE_URL"].present? &&
      ENV["PARTNER_ACTIVITIES_TOKEN"].present? &&
      ENV["PARTNER_AUTH_ORIGIN"].present? &&
      ENV["PARTNER_AUTH_REFERER"].present? &&
      ENV["TEST_PARTNER_AUTH_EMAIL"].present? &&
      ENV["TEST_PARTNER_AUTH_PASSWORD"].present? &&
      ENV["TEST_BRANCH_TOKEN"].present?
  end

  let(:gym_member) { create(:gym_member, email: ENV["TEST_PARTNER_AUTH_EMAIL"], password: ENV["TEST_PARTNER_AUTH_PASSWORD"]) }

  def booking_endpoint
    "#{ENV.fetch("PARTNER_API_BASE_URL")}/api/v1/activities/booking"
  end

  def booking_headers(access_token)
    {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json",
      "Origin" => ENV.fetch("PARTNER_AUTH_ORIGIN"),
      "Referer" => ENV.fetch("PARTNER_AUTH_REFERER")
    }
  end

  def build_booking_params(entry, facility)
    {
      activity_id: entry.partner_activity_id,
      activ_config_id: entry.activ_config_id,
      activity_date: entry.date.iso8601,
      token_branch: facility.evo_token,
      activity_start: entry.start_time.iso8601,
      timezone: "America/Bogota",
      activity_name: entry.class_type.name,
      capacity: 20,
      branch_name: facility.name,
      branch_id: facility.external_id,
      partner_name: "EVO",
      country_code: "CO",
      booking_origin: "WEB"
    }
  end

  describe "POST /api/v1/activities/booking with real partner API" do
    it "returns a successful booking with partner confirmation ID and spot number" do
      # Authenticate the gym member against the partner API to get a valid token
      partner_token = Partner::AuthService.new(gym_member:).login

      # Set up a facility with real partner identifiers
      city = create(:city)
      facility = create(:facility,
        city: city,
        external_id: 84,
        evo_token: ENV.fetch("TEST_BRANCH_TOKEN"),
        name: "Smoke Test Facility")

      # Fetch real schedule entries to get partner_activity_id and activ_config_id
      entries = Partner::ActivitiesService.new.fetch(facility: facility, date: Time.zone.today)
      entry = entries.first

      # Call the partner booking endpoint using the member's access token
      response = HTTParty.post(
        booking_endpoint,
        headers: booking_headers(partner_token.access_token),
        body: build_booking_params(entry, facility).to_json
      )

      expect(response.code).to eq(200)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("OK")
      expect(body["data"]["_id"]).to be_present
      expect(body["data"]["spot_number"]).to be_present
    end

    it "returns error when booking the same session twice" do
      partner_token = Partner::AuthService.new(gym_member:).login

      city = create(:city)
      facility = create(:facility,
        city: city,
        external_id: 84,
        evo_token: ENV.fetch("TEST_BRANCH_TOKEN"),
        name: "Smoke Test Facility")

      entries = Partner::ActivitiesService.new.fetch(facility: facility, date: Time.zone.today)
      entry = entries.first

      params = build_booking_params(entry, facility)
      headers = booking_headers(partner_token.access_token)

      # First booking should succeed
      first_response = HTTParty.post(
        booking_endpoint,
        headers: headers,
        body: params.to_json
      )
      expect(first_response.code).to eq(200)

      # Second booking of the same session should return an error
      second_response = HTTParty.post(
        booking_endpoint,
        headers: headers,
        body: params.to_json
      )

      second_body = JSON.parse(second_response.body)
      expect(second_body["status"]).not_to eq("OK")
      expect(second_body["errors"]).to be_an(Array)
      expect(second_body["errors"].length).to be > 0
    end
  end
end
