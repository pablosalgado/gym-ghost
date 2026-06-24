# frozen_string_literal: true

module GymGhost
  module Scraper
    class ScraperFactory
      def self.build_scraper(url, username = nil, password = nil)
        driver = (ENV["HEADLESS_SCRAPING"].nil? || ENV["HEADLESS_SCRAPING"] == "true") ?
                   DriverFactory.build_headless_driver :
                   DriverFactory.build_driver
        wait = DriverFactory.build_wait
        DefaultScraper.new(url, username, password, driver: driver, wait: wait)
      end
    end
  end
end
