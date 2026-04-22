# frozen_string_literal: true

# Smoke tests hit the REAL website and are excluded from the normal test suite.
#
# Run with:
#   SMOKE_GYM_URL=https://... SMOKE_GYM_USERNAME=you@example.com SMOKE_GYM_PASSWORD=secret \
#     bundle exec rspec spec/smoke --tag smoke --format documentation
#
# Or via Rake:
#   SMOKE_GYM_URL=... SMOKE_GYM_USERNAME=... SMOKE_GYM_PASSWORD=... bundle exec rake spec:smoke

require "rails_helper"
require "gym_ghost/scraper/base"
require "gym_ghost/scraper/default_scraper"
require "gym_ghost/scraper/driver_factory"

RSpec.describe GymGhost::Scraper::DefaultScraper, :smoke do
  let(:driver) {  ENV.fetch("HEADLESS") == "true" ? GymGhost::Scraper::DriverFactory.build_headless_driver : GymGhost::Scraper::DriverFactory.build_driver }
  let(:wait)   { GymGhost::Scraper::DriverFactory.build_wait }

  subject(:scraper) do
    described_class.new(
      ENV.fetch("SMOKE_GYM_URL"),
      ENV.fetch("SMOKE_GYM_USERNAME"),
      ENV.fetch("SMOKE_GYM_PASSWORD"),
      driver: driver,
      wait: wait
    )
  end

  after do
    driver.quit
  rescue StandardError
    nil
  end

  describe "#scrap_cities" do
    it "returns a non-empty array of strings" do
      cities = scraper.scrap_cities

      expect(cities).to be_an(Array)
      expect(cities).not_to be_empty
      expect(cities).to all(be_a(String) & be_truthy)
    end

    it "includes at least one recognisable city name" do
      cities = scraper.scrap_cities

      expect(cities.map(&:upcase)).to eq(cities), "expected city names to be upper-cased"
    end
  end

  describe "#scrap_facilities" do
    it "returns a non-empty array of strings" do
      facilities = scraper.scrap_facilities("BOGOTÁ, D.C.")

      expect(facilities).to be_an(Array)
      expect(facilities).not_to be_empty
      expect(facilities).to all(be_a(String) & be_truthy)
    end
  end

  describe "#scrap_schedule" do
    it "returns a non-empty array of hashes" do
      schedule = scraper.scrap_schedule("BOGOTÁ, D.C.", "Colina", I18n.l(Date.today, format: "%b %d").capitalize)

      expect(schedule).to be_an(Array)
      expect(schedule).not_to be_empty
      expect(schedule).to all(be_a(Hash) & be_truthy)
    end
  end
end
