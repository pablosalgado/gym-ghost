# frozen_string_literal: true

require "rails_helper"
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

  describe "#click_date_element" do
    subject(:click_date_element) { scraper.send(:click_date_element, date, facility) }

    let(:date) { Date.new(2026, 6, 17) }
    let(:facility) { "Colina" }
    let(:today_full_date) { I18n.l(Date.today, format: "%A, %e de %B de %Y").downcase }
    let(:target_full_date) { I18n.l(date, format: "%A, %e de %B de %Y").downcase }
    let(:formatted_day) { I18n.l(date, format: "%b %d").capitalize }

    let(:title_element) { instance_double(Selenium::WebDriver::Element, text: today_full_date) }
    let(:target_title_element) { instance_double(Selenium::WebDriver::Element, text: target_full_date) }
    let(:facility_element) { instance_double(Selenium::WebDriver::Element, text: "Colina") }
    let(:agenda_day_element) { instance_double(Selenium::WebDriver::Element) }

    before do
      allow(driver).to receive(:get)
      allow(driver).to receive(:execute_script)

      stub_const("ScrapeScheduleJob::FACILITIES_CODES", { facility => "Colina" })

      allow(wait).to receive(:until) { |&block| block.call }

      allow(driver).to receive(:find_element)
        .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
        .and_return(title_element)

      allow(driver).to receive(:find_element)
        .with(xpath: "//span[contains(@class, 'cardBook_selectedClubText')]")
        .and_return(facility_element)

      allow(driver).to receive(:find_elements)
        .with(xpath: "//p[contains(@class, 'agenda_days_date__')]")
        .and_return([agenda_day_element])
    end

    context "when the date is on the current week" do
      before do
        allow(driver).to receive(:find_elements)
          .with(xpath: "//p[contains(@class, 'agenda_days_date') and text() = '#{formatted_day}']/parent::*")
          .and_return([agenda_day_element])

        allow(driver).to receive(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .and_return(title_element, target_title_element)
      end

      it "clicks the date element" do
        click_date_element
        expect(driver).to have_received(:execute_script).with("arguments[0].click();", agenda_day_element)
      end

      it "does not navigate to the next week" do
        click_date_element
        expect(driver).not_to have_received(:find_elements)
          .with(xpath: "//*[local-name() = 'svg' and contains(@class, 'agenda_arrow')]")
      end

      it "verifies the correct schedule loaded after clicking" do
        click_date_element
        expect(driver).to have_received(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .at_least(:twice)
      end
    end

    context "when the date is one week ahead" do
      let(:next_sunday) { Date.today.next_week(:monday) - 1.day }
      let(:next_sunday_title) { I18n.l(next_sunday, format: "%A, %e de %B de %Y").downcase }
      let(:next_sunday_element) { instance_double(Selenium::WebDriver::Element, text: next_sunday_title) }
      let(:next_week_arrow) { instance_double(Selenium::WebDriver::Element) }

      before do
        allow(next_week_arrow).to receive(:click)

        allow(driver).to receive(:find_elements)
          .with(xpath: "//p[contains(@class, 'agenda_days_date') and text() = '#{formatted_day}']/parent::*")
          .and_return([], [agenda_day_element])

        allow(driver).to receive(:find_elements)
          .with(xpath: "//*[local-name() = 'svg' and contains(@class, 'agenda_arrow')]")
          .and_return([next_week_arrow])

        allow(driver).to receive(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .and_return(title_element, next_sunday_element, target_title_element)
      end

      it "clicks the next week arrow" do
        click_date_element
        expect(next_week_arrow).to have_received(:click)
      end

      it "clicks the date element" do
        click_date_element
        expect(driver).to have_received(:execute_script).with("arguments[0].click();", agenda_day_element)
      end

      it "verifies the agenda advanced to the correct week" do
        click_date_element
        expect(driver).to have_received(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .exactly(3).times
      end
    end

    context "when the date is multiple weeks ahead" do
      let(:first_sunday) { Date.today.next_week(:monday) - 1.day }
      let(:second_sunday) { first_sunday + 7.days }
      let(:first_sunday_title) { I18n.l(first_sunday, format: "%A, %e de %B de %Y").downcase }
      let(:second_sunday_title) { I18n.l(second_sunday, format: "%A, %e de %B de %Y").downcase }
      let(:first_sunday_element) { instance_double(Selenium::WebDriver::Element, text: first_sunday_title) }
      let(:second_sunday_element) { instance_double(Selenium::WebDriver::Element, text: second_sunday_title) }
      let(:next_week_arrow) { instance_double(Selenium::WebDriver::Element) }

      before do
        allow(next_week_arrow).to receive(:click)

        allow(driver).to receive(:find_elements)
          .with(xpath: "//p[contains(@class, 'agenda_days_date') and text() = '#{formatted_day}']/parent::*")
          .and_return([], [], [agenda_day_element])

        allow(driver).to receive(:find_elements)
          .with(xpath: "//*[local-name() = 'svg' and contains(@class, 'agenda_arrow')]")
          .and_return([next_week_arrow], [next_week_arrow])

        allow(driver).to receive(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .and_return(title_element, first_sunday_element, second_sunday_element, target_title_element)
      end

      it "clicks the next week arrow twice" do
        click_date_element
        expect(next_week_arrow).to have_received(:click).twice
      end

      it "clicks the date element" do
        click_date_element
        expect(driver).to have_received(:execute_script).with("arguments[0].click();", agenda_day_element)
      end

      it "verifies the agenda advanced through two weeks" do
        click_date_element
        expect(driver).to have_received(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .exactly(4).times
      end
    end
  end
end
