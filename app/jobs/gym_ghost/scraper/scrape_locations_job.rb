module GymGhost
  module Scraper
    class ScrapeLocationsJob < ApplicationJob
      queue_as :default

      def perform(url = ENV["SMOKE_GYM_URL"], scraper_factory = ScraperFactory)
        Rails.logger.info("Scraping locations for #{url}")
        save_locations(url, scraper_factory)
      end

      private

      def save_locations(url, scraper_factory)
        scraper = scraper_factory.build_scraper(url)
        cities = scraper.scrape_cities
        cities.each { |city| process_city(scraper, city) }
      ensure
        scraper&.end_session
      end

      def process_city(scraper, city_name)
        city = City.find_or_create_by!(name: city_name)
        facilities = scraper.scrape_facilities(city_name)
        facilities.each { |facility_name| city.facilities.find_or_create_by!(name: facility_name) }
      end
    end
  end
end
