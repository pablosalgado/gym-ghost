# frozen_string_literal: true

require "selenium-webdriver"

module GymGhost
  module Scraper
    class DriverFactory
      def self.build_driver(driver_options: [])
        options = Selenium::WebDriver::Options.firefox.tap do |options|
          driver_options.each { |option| options.add_argument(option) }
        end

        Selenium::WebDriver.for(:firefox, options: options)
      end

      def self.build_headless_driver
        build_driver(driver_options: %w[ --headless ])
      end

      def self.build_wait
        Selenium::WebDriver::Wait.new
      end
    end
  end
end
