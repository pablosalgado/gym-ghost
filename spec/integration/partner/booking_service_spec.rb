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

  let(:gym_member) do
    GymMember.find_by(email: ENV["TEST_PARTNER_AUTH_EMAIL"]) ||
    create(:gym_member, email: ENV["TEST_PARTNER_AUTH_EMAIL"], password: ENV["TEST_PARTNER_AUTH_PASSWORD"])
  end

  describe "POST /api/v1/activities/booking with real partner API" do
    it "returns a successful booking with partner confirmation ID and spot number" do
      # Fetch real facility
      facility = Partner::FacilitiesService.new.sync.find { |facility| facility.display_name == "C.C Parque La Colina" }

      # Fetch real schedule entry for today
      schedule_entries = Partner::ActivitiesService.new.fetch(facility: facility, date: Time.zone.today)
      schedule_entry = schedule_entries.select { |schedule_entry| schedule_entry.start_time > Time.zone.tomorrow.midnight }.first

      Partner::BookingService.new(gym_member:).book(schedule_entry:)

      expect(response.code).to eq(200)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("OK")
      expect(body["data"]["_id"]).to be_present
      expect(body["data"]["spot_number"]).to be_present
    end
  end
end
