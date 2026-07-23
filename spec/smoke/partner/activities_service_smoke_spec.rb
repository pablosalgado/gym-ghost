require "rails_helper"

RSpec.describe Partner::ActivitiesService, smoke: true do
  before do
    skip "Set PARTNER_API_BASE_URL, PARTNER_ACTIVITIES_TOKEN, " \
         "PARTNER_AUTH_REFERER, PARTNER_AUTH_ORIGIN, " \
         "and TEST_BRANCH_TOKEN to run " \
         "smoke tests for ActivitiesService" unless
      ENV["PARTNER_API_BASE_URL"].present? &&
      ENV["PARTNER_ACTIVITIES_TOKEN"].present? &&
      ENV["PARTNER_AUTH_REFERER"].present? &&
      ENV["PARTNER_AUTH_ORIGIN"].present? &&
      ENV["TEST_BRANCH_TOKEN"].present?
  end

  describe "#fetch with real partner activities API" do
    it "persists ClassType and ScheduleEntry records" do
      city = City.create!(city_name: "Test City")

      facility = Facility.create!(
        external_id: 84,
        name: "Smoke Test Facility",
        evo_token: "#{ENV.fetch("TEST_BRANCH_TOKEN")}",
        display_name: "Smoke Test Display",
        city: city
      )

      entries = described_class.new.fetch(facility: facility, date: Time.zone.today)

      # Assert the result is a non-empty array of ScheduleEntry records
      expect(entries).to be_an(Array)
      expect(entries.length).to be > 0
      expect(entries.first).to be_a(ScheduleEntry)

      # Assert at least one ClassType and one ScheduleEntry were persisted
      expect(ClassType.count).to be > 0
      expect(ScheduleEntry.count).to be > 0
    end
  end
end
