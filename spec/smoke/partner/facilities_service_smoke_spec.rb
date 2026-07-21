require "rails_helper"

RSpec.describe Partner::FacilitiesService, smoke: true do
  before do
    skip "Set PARTNER_BRANCHES_API_BASE_URL, PARTNER_BRANCHES_BRAND, " \
         "PARTNER_AUTH_TOKEN, PARTNER_AUTH_ORIGIN, " \
         "and PARTNER_AUTH_REFERER to run " \
         "smoke tests for FacilitiesService" unless
      ENV["PARTNER_BRANCHES_API_BASE_URL"].present? &&
      ENV["PARTNER_BRANCHES_BRAND"].present? &&
      ENV["PARTNER_AUTH_TOKEN"].present? &&
      ENV["PARTNER_AUTH_ORIGIN"].present? &&
      ENV["PARTNER_AUTH_REFERER"].present?
  end

  describe "#sync with real partner branches API" do
    it "persists at least one Facility and one City" do
      facilities = described_class.new.sync

      expect(facilities).to be_an(Array)
      expect(facilities.length).to be > 0

      # At least one City persisted with non-nil city_name
      expect(City.count).to be > 0
      city = City.first
      expect(city.city_name).to be_present

      # At least one Facility persisted with all expected columns non-nil external_id
      expect(Facility.count).to be > 0
      facility = Facility.first
      expect(facility.external_id).to be_present
      # name, evo_token, display_name may legitimately be "" from the upstream,
      # but they should NOT be nil per the issue spec:
      expect(facility.name).not_to be_nil
      expect(facility.evo_token).not_to be_nil
      expect(facility.display_name).not_to be_nil
    end
  end
end
