# frozen_string_literal: true

require "spec_helper"
require "selenium-webdriver"
require "gym_ghost/scraper/base"
require "gym_ghost/scraper/default_scraper"

RSpec.describe GymGhost::Scraper::DefaultScraper do
  subject(:scraper) { described_class.new(url, username, password, driver: driver, wait: wait) }

  let(:url) { "https://gym.example.com" }
  let(:username) { "user@example.com" }
  let(:password) { "secret" }
  let(:driver) { instance_double(Selenium::WebDriver::Driver) }
  let(:wait) { instance_double(Selenium::WebDriver::Wait) }

  describe "#scrape_cities" do
    let(:city_elements) do
      [ instance_double(Selenium::WebDriver::Element, text: "BOGOTÁ"),
        instance_double(Selenium::WebDriver::Element, text: "MEDELLÍN") ]
    end

    before do
      allow(driver).to receive(:get)

      allow(driver).to receive(:find_element)
        .with(xpath: "//button[contains(., 'Cambiar de sede')]")
        .and_return(instance_double(Selenium::WebDriver::Element)
          .tap { |el| allow(el).to receive(:displayed?).and_return(true) }
          .tap { |el| allow(el).to receive(:click) })

      allow(driver).to receive(:find_element)
        .with(xpath: "//div[@aria-labelledby='city-select-label']")
        .and_return(instance_double(Selenium::WebDriver::Element)
          .tap { |el| allow(el).to receive(:displayed?).and_return(true) }
          .tap { |el| allow(el).to receive(:click) })

      allow(driver).to receive(:find_elements)
        .with(xpath: "//ul[@aria-labelledby='city-select-label']/li")
        .and_return(city_elements)

      allow(wait).to receive(:until)
    end

    it "navigates to the URL" do
      scraper.scrape_cities
      expect(driver).to have_received(:get).with(url)
    end

    it "clicks the city selector button" do
      scraper.scrape_cities
      expect(driver).to have_received(:find_element)
        .with(xpath: "//button[contains(., 'Cambiar de sede')]")
    end

    it "returns the list of city names" do
      expect(scraper.scrape_cities).to eq(%w[BOGOTÁ MEDELLÍN])
    end
  end
end
