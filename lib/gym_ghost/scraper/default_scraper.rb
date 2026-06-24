# frozen_string_literal: true

module GymGhost
  module Scraper
    class DefaultScraper < Base
      def initialize(...)
        super(...)
      end

      def self.gym_id
        "default"
      end

      def scrape_cities
        navigate_to_cities
        build_cities
      end

      def scrape_facilities(city)
        navigate_to_facilities(city)
        build_facilities
      end

      def scrape_schedule(city, facility, date)
        Rails.logger.debug("Scraping day schedule for City: #{city}, Facility: #{facility} and Date: #{date}")

        navigate_to_schedule(city, facility, date)
        build_and_merge_location(date: date, facility: facility, city: city)
      end

      def login
        raise GymGhost::Scraper::MissingCredentialsError if @username.nil? || @password.nil?

        navigate_to_login

        email_xpath = "//input[@type = 'email']"
        password_xpath = "//input[@type = 'password']"

        email_element = wait.until { driver.find_elements(:xpath, email_xpath).first }
        password_element = wait.until { driver.find_elements(:xpath, password_xpath).first }

        email_element.send_keys(@username)
        password_element.send_keys(@password)

        submit_xpath = "//button[@type = 'submit']"
        submit_button = wait.until { driver.find_elements(:xpath, submit_xpath).first }
        submit_button.click

        true
      end

      private

      def navigate_to_cities
        click_change_facility_button
        click_city_select
      end

      def build_cities
        xpath = "//ul[@aria-labelledby='city-select-label']/li"
        driver.find_elements(xpath: xpath).map { |element| element.text }
      end

      def navigate_to_facilities(city)
        navigate_to_city(city)
      end

      def build_facilities
        xpath = "//button/span[contains(@class, 'font-poppins')]"
        driver.find_elements(xpath: xpath).map { |element| element.text }
      end

      def navigate_to_schedule(city, facility, date)
        navigate_to_facility(city, facility)
        click_date_element(date, facility)
      end

      def navigate_to_facility(city, facility)
        navigate_to_city(city)
        click_facility_element(facility)
      end

      def navigate_to_city(city)
        click_change_facility_button
        click_city_select
        click_city_element(city)
      end

      def click_change_facility_button
        # driver.get(url)
        button = driver.find_element(xpath: "//button[contains(., 'Cambiar de sede')]")
        wait.until { button.displayed? && button.enabled? }
        button.click
      end

      def build_and_merge_location(**options)
        build_schedule.map { |item| item.merge(**options) }
      end

      def build_schedule
        xpath = "//div[starts-with(@class, 'cardBook_info_container_main')]"
        wait.until { driver.find_elements(xpath: xpath).any? }
        process_schedule(xpath)
      end

      def process_schedule(xpath)
        driver.find_elements(xpath: xpath).map { |element| process_schedule_item(element) }
      end

      def process_schedule_item(element)
        extract_time_and_duration(element).merge(extract_activity(element))
      end

      def extract_time_and_duration(element)
        extract_time(element).merge(extract_duration(element))
      end

      def extract_time(element)
        xpath = ".//child::*/span[starts-with(@class, 'cardBook_time')]"
        { time: element.find_element(xpath: xpath).text }
      end

      def extract_duration(element)
        xpath = ".//child::*/span[starts-with(@class, 'cardBook_duration')]"
        { duration: element.find_element(xpath: xpath).text }
      end

      def extract_activity(element)
        xpath = ".//child::*/span[starts-with(@class, 'cardBook_explain')]"
        { activity: element.find_element(xpath: xpath).text }
      end

      def click_city_select
        city_select = driver.find_element(xpath: "//div[@aria-labelledby='city-select-label']")
        wait.until { city_select.displayed? && city_select.enabled? }
        city_select.click
      end

      def click_city_element(city)
        city_element = driver.find_element(xpath: "//ul[@aria-labelledby='city-select-label']/li/span[starts-with(., '#{city}')]")
        wait.until { city_element.displayed? && city_element.enabled? }
        city_element.click
      end

      def click_facility_element(facility)
        facility_element_xpath = "//button/span[. = '#{facility}']"
        facility_element = wait.until { driver.find_elements(xpath: facility_element_xpath).first }
        driver.execute_script("arguments[0].click();", facility_element)
      end

      def click_date_element(date, facility)
        formatted_day = I18n.l(date, format: "%b %d").capitalize
        Rails.logger.debug("click_date_element: Starting for date=#{date}, facility=#{facility}, formatted=#{formatted_day}")

        wait_for_schedule_load(facility)
        agenda_day_element = find_day_in_agenda(formatted_day) || advance_weeks_until_found(formatted_day, facility)

        Rails.logger.debug("click_date_element: Date '#{formatted_day}' found, clicking it")
        click_element(agenda_day_element)
        verify_schedule_loaded(date, facility)
      end

      def wait_for_schedule_load(facility)
        today_full_date = I18n.l(Date.today, format: "%A, %e de %B de %Y").downcase
        full_date_xpath = "//span[contains(@class, 'agenda_title_date')]"
        facility_xpath = "//span[contains(@class, 'cardBook_selectedClubText')]"

        Rails.logger.debug("click_date_element: Waiting for schedule to load — day='#{today_full_date}', facility='#{ScrapeScheduleJob::FACILITIES_CODES[facility]}'")
        wait.until do
          full_date_element = driver.find_elements(xpath: full_date_xpath).first
          facility_element = driver.find_elements(xpath: facility_xpath).first

          full_date_element.present? &&
            facility_element.present? &&
            full_date_element.text == today_full_date &&
            facility_element.text == ScrapeScheduleJob::FACILITIES_CODES[facility]
        end
        Rails.logger.debug("click_date_element: Schedule loaded successfully")

        wait.until { driver.find_elements(xpath: "//p[contains(@class, 'agenda_days_date__')]").any? }
        Rails.logger.debug("click_date_element: Agenda days visible")
      end

      def find_day_in_agenda(formatted_day)
        xpath = "//p[contains(@class, 'agenda_days_date') and text() = '#{formatted_day}']/parent::*"
        driver.find_elements(xpath: xpath).first
      end

      def advance_weeks_until_found(formatted_day, facility)
        next_sunday = Date.today.next_week(:monday) - 1.day
        week_offset = 1

        loop do
          Rails.logger.debug("click_date_element: Date '#{formatted_day}' not found, navigating to week #{week_offset}")
          advance_one_week_and_wait(next_sunday, facility)
          next_sunday += 7.days
          week_offset += 1

          element = find_day_in_agenda(formatted_day)
          return element if element
        end
      end

      def advance_one_week_and_wait(sunday_date, facility)
        next_week_xpath = "//*[local-name() = 'svg' and contains(@class, 'agenda_arrow')]"
        next_week_element = wait.until { driver.find_elements(xpath: next_week_xpath).last }
        Rails.logger.debug("click_date_element: Clicking next week arrow")
        next_week_element.click

        expected_title = I18n.l(sunday_date, format: "%A, %e de %B de %Y").downcase
        title_xpath = "//span[contains(@class, 'agenda_title_date')]"
        facility_xpath = "//span[contains(@class, 'cardBook_selectedClubText')]"
        Rails.logger.debug("click_date_element: Waiting for agenda to advance to '#{expected_title}'")
        wait.until { driver.find_element(xpath: title_xpath).text == expected_title && driver.find_element(xpath: facility_xpath).text == ScrapeScheduleJob::FACILITIES_CODES[facility] }
      end

      def click_element(element)
        driver.execute_script("arguments[0].click();", element)
      end

      def verify_schedule_loaded(date, facility)
        target_title = I18n.l(date, format: "%A, %e de %B de %Y").downcase
        title_xpath = "//span[contains(@class, 'agenda_title_date')]"
        facility_xpath = "//span[contains(@class, 'cardBook_selectedClubText')]"
        Rails.logger.debug("click_date_element: Verifying schedule loaded for '#{target_title}'")
        wait.until { driver.find_element(xpath: title_xpath).text == target_title && driver.find_element(xpath: facility_xpath).text == ScrapeScheduleJob::FACILITIES_CODES[facility] }
        Rails.logger.debug("click_date_element: Schedule loaded successfully for #{date}")
      end

      def navigate_to_login
        close_facility_xpath = "//button[@aria-label = 'Cerrar']"
        driver.find_element(xpath: close_facility_xpath).click

        login_xpath = "//p[. = 'Inicia sesión']/parent::*"
        login_element = wait.until { driver.find_elements(xpath: login_xpath).first }
        click_element(login_element)
      end
    end
  end
end
