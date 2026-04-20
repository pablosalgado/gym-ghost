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
        driver.get(url)
        click_change_facility_button
        click_city_select
        driver.find_elements(xpath: "//ul[@aria-labelledby='city-select-label']/li").map { |element| element.text }
      end

      private

      def click_change_facility_button
        change_facility_button = driver.find_element(xpath: "//button[contains(., 'Cambiar de sede')]")
        wait.until { change_facility_button.displayed? }
        change_facility_button.click
      end

      def click_city_select
        city_select = driver.find_element(xpath: "//div[@aria-labelledby='city-select-label']")
        wait.until { city_select.displayed? }
        city_select.click
      end
    end
  end
end
