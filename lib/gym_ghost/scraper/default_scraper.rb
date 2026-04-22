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

      def scrap_cities
        navigate_to_cities
        build_cities
      end

      def scrap_facilities(city)
        navigate_to_facilities(city)
        build_facilities
      end

      def scrap_schedule(city, facility, date)
        navigate_to_schedule(city, facility, date)
        build_and_merge_location(date: date, facility: facility, city: city)
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
        click_date_element(date)
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
        driver.get(url)
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
        facility_element = driver.find_element(xpath: "//span[. = '#{facility}']")
        wait.until { facility_element.displayed? && facility_element.enabled? }
        driver.execute_script("arguments[0].click();", facility_element)
      end

      def click_date_element(date)
        xpath = "//p[contains(., '#{date}')]/parent::*"

        wait.until { driver.find_element(xpath: xpath) }

        date_element = driver.find_element(xpath: xpath)
        wait.until { date_element.displayed? && date_element.enabled? }
        driver.execute_script("arguments[0].click();", date_element)

        wait.until { driver.find_element(xpath: xpath) }
      end
    end
  end
end
