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

  describe "#login" do
    let(:email_element) { instance_double(Selenium::WebDriver::Element) }
    let(:password_element) { instance_double(Selenium::WebDriver::Element) }
    let(:submit_element) { instance_double(Selenium::WebDriver::Element) }
    let(:close_button) { instance_double(Selenium::WebDriver::Element) }
    let(:login_element) { instance_double(Selenium::WebDriver::Element) }

    before do
      allow(driver).to receive(:get)
      allow(driver).to receive(:execute_script)
      allow(wait).to receive(:until) { |&block| block.call }

      allow(driver).to receive(:find_element)
        .with(xpath: "//button[@aria-label = 'Cerrar']")
        .and_return(close_button)
      allow(close_button).to receive(:click)

      allow(driver).to receive(:find_elements)
        .with(xpath: "//p[. = 'Inicia sesión']/parent::*")
        .and_return([ login_element ])

      allow(driver).to receive(:find_elements)
        .with(:xpath, "//input[@type = 'email']")
        .and_return([ email_element ])
      allow(email_element).to receive(:send_keys)

      allow(driver).to receive(:find_elements)
        .with(:xpath, "//input[@type = 'password']")
        .and_return([ password_element ])
      allow(password_element).to receive(:send_keys)

      allow(driver).to receive(:find_elements)
        .with(:xpath, "//button[@type = 'submit']")
        .and_return([ submit_element ])
      allow(submit_element).to receive(:click)
    end

    it "closes the facility dialog and navigates to login" do
      scraper.login
      expect(driver).to have_received(:find_element)
        .with(xpath: "//button[@aria-label = 'Cerrar']")
      expect(close_button).to have_received(:click)
      expect(driver).to have_received(:find_elements)
        .with(xpath: "//p[. = 'Inicia sesión']/parent::*")
      expect(driver).to have_received(:execute_script).with("arguments[0].click();", login_element)
    end

    it "fills in the email field" do
      scraper.login
      expect(driver).to have_received(:find_elements)
        .with(:xpath, "//input[@type = 'email']")
      expect(email_element).to have_received(:send_keys).with(username)
    end

    it "fills in the password field" do
      scraper.login
      expect(driver).to have_received(:find_elements)
        .with(:xpath, "//input[@type = 'password']")
      expect(password_element).to have_received(:send_keys).with(password)
    end

    it "submits the login form" do
      scraper.login
      expect(driver).to have_received(:find_elements)
        .with(:xpath, "//button[@type = 'submit']")
      expect(submit_element).to have_received(:click)
    end

    context "when username is nil" do
      let(:username) { nil }

      it "raises MissingCredentialsError" do
        expect { scraper.login }.to raise_error(GymGhost::Scraper::MissingCredentialsError)
      end
    end

    context "when password is nil" do
      let(:password) { nil }

      it "raises MissingCredentialsError" do
        expect { scraper.login }.to raise_error(GymGhost::Scraper::MissingCredentialsError)
      end
    end

    context "when both username and password are nil" do
      let(:username) { nil }
      let(:password) { nil }

      it "raises MissingCredentialsError" do
        expect { scraper.login }.to raise_error(GymGhost::Scraper::MissingCredentialsError)
      end
    end

    context "when the email input is not found" do
      before do
        allow(driver).to receive(:find_elements)
          .with(:xpath, "//input[@type = 'email']")
          .and_return([])

        allow(wait).to receive(:until) { raise Selenium::WebDriver::Error::TimeoutError }
      end

      it "raises TimeoutError on nil" do
        expect { scraper.login }.to raise_error(Selenium::WebDriver::Error::TimeoutError)
      end
    end

    context "when the password input is not found" do
      before do
        allow(driver).to receive(:find_elements)
          .with(:xpath, "//input[@type = 'password']")
          .and_return([])

        allow(wait).to receive(:until) { raise Selenium::WebDriver::Error::TimeoutError }
      end

      it "raises TimeoutError on nil" do
        expect { scraper.login }.to raise_error(Selenium::WebDriver::Error::TimeoutError)
      end
    end

    context "when the submit button is not found" do
      before do
        allow(driver).to receive(:find_elements)
          .with(:xpath, "//button[@type = 'submit']")
          .and_return([])

        allow(wait).to receive(:until) { raise Selenium::WebDriver::Error::TimeoutError }
      end

      it "raises TimeoutError on nil" do
        expect { scraper.login }.to raise_error(Selenium::WebDriver::Error::TimeoutError)
      end
    end
  end

  describe "#navigate_to_login" do
    subject(:navigate_to_login) { scraper.send(:navigate_to_login) }

    let(:close_button) { instance_double(Selenium::WebDriver::Element) }
    let(:login_element) { instance_double(Selenium::WebDriver::Element) }

    before do
      allow(driver).to receive(:get)
      allow(driver).to receive(:execute_script)
      allow(wait).to receive(:until) { |&block| block.call }

      allow(driver).to receive(:find_element)
        .with(xpath: "//button[@aria-label = 'Cerrar']")
        .and_return(close_button)
      allow(close_button).to receive(:click)

      allow(driver).to receive(:find_elements)
        .with(xpath: "//p[. = 'Inicia sesión']/parent::*")
        .and_return([ login_element ])
    end

    it "closes the facility popup" do
      navigate_to_login
      expect(driver).to have_received(:find_element)
        .with(xpath: "//button[@aria-label = 'Cerrar']")
      expect(close_button).to have_received(:click)
    end

    it "clicks the login button" do
      navigate_to_login
      expect(driver).to have_received(:find_elements)
        .with(xpath: "//p[. = 'Inicia sesión']/parent::*")
      expect(driver).to have_received(:execute_script).with("arguments[0].click();", login_element)
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

      allow(driver).to receive(:find_elements)
        .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
        .and_return([ title_element ])

      allow(driver).to receive(:find_elements)
        .with(xpath: "//span[contains(@class, 'cardBook_selectedClubText')]")
        .and_return([ facility_element ])

      allow(driver).to receive(:find_element)
        .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
        .and_return(title_element)

      allow(driver).to receive(:find_element)
        .with(xpath: "//span[contains(@class, 'cardBook_selectedClubText')]")
        .and_return(facility_element)

      allow(driver).to receive(:find_elements)
        .with(xpath: "//p[contains(@class, 'agenda_days_date__')]")
        .and_return([ agenda_day_element ])
    end

    context "when the date is on the current week" do
      before do
        allow(driver).to receive(:find_elements)
          .with(xpath: "//p[contains(@class, 'agenda_days_date') and text() = '#{formatted_day}']/parent::*")
          .and_return([ agenda_day_element ])

        allow(driver).to receive(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .and_return(target_title_element)
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
          .once
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
          .and_return([], [ agenda_day_element ])

        allow(driver).to receive(:find_elements)
          .with(xpath: "//*[local-name() = 'svg' and contains(@class, 'agenda_arrow')]")
          .and_return([ next_week_arrow ])

        allow(driver).to receive(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .and_return(next_sunday_element, target_title_element)
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
          .exactly(2).times
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
          .and_return([], [], [ agenda_day_element ])

        allow(driver).to receive(:find_elements)
          .with(xpath: "//*[local-name() = 'svg' and contains(@class, 'agenda_arrow')]")
          .and_return([ next_week_arrow ], [ next_week_arrow ])

        allow(driver).to receive(:find_element)
          .with(xpath: "//span[contains(@class, 'agenda_title_date')]")
          .and_return(first_sunday_element, second_sunday_element, target_title_element)
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
          .exactly(3).times
      end
    end
  end

  describe "#reserve_class" do
    subject(:reserve) { scraper.reserve_class(city, facility, date, time) }

    let(:city) { "BOGOTÁ, D.C." }
    let(:facility) { "Colina" }
    let(:date) { Date.new(2026, 6, 17) }
    let(:time) { "07:00" }
    let(:close_button) { instance_double(Selenium::WebDriver::Element) }
    let(:login_element) { instance_double(Selenium::WebDriver::Element) }
    let(:email_element) { instance_double(Selenium::WebDriver::Element) }
    let(:password_element) { instance_double(Selenium::WebDriver::Element) }
    let(:submit_element) { instance_double(Selenium::WebDriver::Element) }
    let(:time_element) { instance_double(Selenium::WebDriver::Element, text: time) }
    let(:card) { instance_double(Selenium::WebDriver::Element) }
    let(:reserve_button) { instance_double(Selenium::WebDriver::Element) }
    let(:confirm_button) { instance_double(Selenium::WebDriver::Element) }

    before do
      allow(driver).to receive(:get)
      allow(driver).to receive(:execute_script)
      allow(wait).to receive(:until) { |&block| block.call }

      # Login stubs
      allow(driver).to receive(:find_element)
        .with(xpath: "//button[@aria-label = 'Cerrar']")
        .and_return(close_button)
      allow(close_button).to receive(:click)

      allow(driver).to receive(:find_elements)
        .with(xpath: "//p[. = 'Inicia sesión']/parent::*")
        .and_return([ login_element ])

      allow(driver).to receive(:find_elements)
        .with(:xpath, "//input[@type = 'email']")
        .and_return([ email_element ])
      allow(email_element).to receive(:send_keys)

      allow(driver).to receive(:find_elements)
        .with(:xpath, "//input[@type = 'password']")
        .and_return([ password_element ])
      allow(password_element).to receive(:send_keys)

      allow(driver).to receive(:find_elements)
        .with(:xpath, "//button[@type = 'submit']")
        .and_return([ submit_element ])
      allow(submit_element).to receive(:click)

      # Stub the navigation phase — it is tested separately
      allow(scraper).to receive(:navigate_to_schedule)

      allow(driver).to receive(:find_elements)
        .with(xpath: "//div[starts-with(@class, 'cardBook_info_container_main')]")
        .and_return([ card ])

      allow(card).to receive(:find_element)
        .with(xpath: ".//span[starts-with(@class, 'cardBook_time')]")
        .and_return(time_element)

      allow(card).to receive(:find_element)
        .with(xpath: ".//button[contains(translate(., 'RESERVAR', 'reservar'), 'reservar')]")
        .and_return(reserve_button)
      allow(reserve_button).to receive(:displayed?).and_return(true)
      allow(reserve_button).to receive(:enabled?).and_return(true)
      allow(reserve_button).to receive(:click)

      allow(driver).to receive(:find_element)
        .with(xpath: "//button[contains(translate(., 'CONFIRMAR', 'confirmar'), 'confirmar')]")
        .and_return(confirm_button)
      allow(confirm_button).to receive(:displayed?).and_return(true)
      allow(confirm_button).to receive(:enabled?).and_return(true)
      allow(confirm_button).to receive(:click)
    end

    it "logs in" do
      reserve
      expect(driver).to have_received(:find_elements)
        .with(:xpath, "//input[@type = 'email']")
    end

    it "navigates to the schedule" do
      reserve
      expect(scraper).to have_received(:navigate_to_schedule).with(city, facility, date)
    end

    it "finds the class card by time" do
      reserve
      expect(card).to have_received(:find_element)
        .with(xpath: ".//span[starts-with(@class, 'cardBook_time')]")
    end

    it "clicks the reserve button" do
      reserve
      expect(reserve_button).to have_received(:click)
    end

    it "clicks the confirm button" do
      reserve
      expect(confirm_button).to have_received(:click)
    end

    it "returns true" do
      expect(reserve).to be true
    end

    context "when credentials are missing" do
      let(:username) { nil }

      it "raises MissingCredentialsError" do
        expect { reserve }.to raise_error(GymGhost::Scraper::MissingCredentialsError)
      end
    end

    context "when the class is not found" do
      let(:time) { "99:99" }
      let(:other_time_element) { instance_double(Selenium::WebDriver::Element, text: "08:00") }

      before do
        allow(card).to receive(:find_element)
          .with(xpath: ".//span[starts-with(@class, 'cardBook_time')]")
          .and_return(other_time_element)
      end

      it "returns false" do
        expect(reserve).to be false
      end
    end
  end
end
