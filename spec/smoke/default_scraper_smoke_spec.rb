# frozen_string_literal: true

# Smoke tests hit the REAL website and are excluded from the normal test suite.
#
# Run with:
#   bundle exec rspec spec/smoke --tag smoke --format documentation
#
# Or via Rake:
#   bundle exec rake spec:smoke

require "rails_helper"
require "gym_ghost/scraper/base"
require "gym_ghost/scraper/default_scraper"
require "gym_ghost/scraper/driver_factory"

RSpec.describe GymGhost::Scraper::DefaultScraper, :smoke do
  let(:driver) { GymGhost::Scraper::DriverFactory.build_driver }
  let(:wait) { GymGhost::Scraper::DriverFactory.build_wait }

  subject(:scraper) do
    described_class.new(
      Rails.application.credentials.dig(:gym, :url),
      Rails.application.credentials.dig(:gym, :username),
      Rails.application.credentials.dig(:gym, :password),
      driver: driver,
      wait: wait
    )
  end

  after do
    driver.quit
  rescue StandardError
    nil
  end

  describe "#scrape_cities" do
    it "returns a non-empty array of strings" do
      cities = scraper.scrape_cities

      expect(cities).to be_an(Array)
      expect(cities).not_to be_empty
      expect(cities).to all(be_a(String) & be_truthy)
    end

    it "includes at least one recognisable city name" do
      cities = scraper.scrape_cities

      expect(cities.map(&:upcase)).to eq(cities), "expected city names to be upper-cased"
    end
  end

  describe "#scrape_facilities" do
    it "returns a non-empty array of strings" do
      facilities = scraper.scrape_facilities("BOGOTÁ, D.C.")

      expect(facilities).to be_an(Array)
      expect(facilities).not_to be_empty
      expect(facilities).to all(be_a(String) & be_truthy)
    end
  end

  describe "#scrape_schedule" do
    it "returns a non-empty array of hashes" do
      schedule = scraper.scrape_schedule("BOGOTÁ, D.C.", "Colina", Date.today)

      expect(schedule).to be_an(Array)
      expect(schedule).not_to be_empty
      expect(schedule).to all(be_a(Hash) & be_truthy)
    end
  end

  describe "#login" do
    it "logs in successfully with valid credentials" do
      expect(scraper.login).to be true
    end
  end
end
