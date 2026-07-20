require "rails_helper"

RSpec.describe Partner::ActivitiesService, smoke: true do
  self.use_transactional_tests = false

  before do
    skip "Set PARTNER_API_BASE_URL, PARTNER_ACTIVITIES_TOKEN, " \
         "PARTNER_AUTH_REFERER, and PARTNER_AUTH_ORIGIN to run " \
         "smoke tests for ActivitiesService" unless
      ENV["PARTNER_API_BASE_URL"].present? &&
      ENV["PARTNER_ACTIVITIES_TOKEN"].present? &&
      ENV["PARTNER_AUTH_REFERER"].present? &&
      ENV["PARTNER_AUTH_ORIGIN"].present?
  end

  describe "#fetch with real partner activities API" do
    it "persists Activity and ScheduleEntry records" do
      city = City.create!(city_name: "Test City")

      facility = Facility.create!(
        external_id: 84,
        name: "Smoke Test Facility",
        evo_token: "evo-token-abc",
        display_name: "Smoke Test Display",
        city: city
      )

      entries = described_class.new.fetch(facility: facility, date: Time.zone.today)

      # Assert the result is a non-empty array of ScheduleEntry records
      expect(entries).to be_an(Array)
      expect(entries.length).to be > 0
      expect(entries.first).to be_a(ScheduleEntry)

      # Assert at least one Activity and one ScheduleEntry were persisted
      expect(Activity.count).to be > 0
      expect(ScheduleEntry.count).to be > 0
    end
  end
end
