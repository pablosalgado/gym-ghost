# frozen_string_literal: true

module GymGhost
  module Scraper
    class ScraperFactory
      def self.build_scraper(url, username, password)
        driver = DriverFactory.build_driver
        wait = DriverFactory.build_wait
        DefaultScraper.new(url, username, password, driver: driver, wait: wait)
      end
    end
  end
end
