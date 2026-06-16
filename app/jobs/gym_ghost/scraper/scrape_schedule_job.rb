module GymGhost
  module Scraper
    class ScrapeScheduleJob < ApplicationJob
      CITIES = [ "BOGOTÁ, D.C." ].freeze
      FACILITIES_CODES = {
        "C.C Parque La Colina" => "CCColina",
        "Colina" => "Colina",
        "Cedro Bolivar" => "CedroBolivar",
        "Corporate Center" => "HotelMarriotSalitre"
      }.freeze

      queue_as :default

      def perform(date, facility, url = ENV["SMOKE_GYM_URL"], scraper_factory = ScraperFactory)
        Rails.logger.info("Scraping schedule for #{url}")
        save_schedule(date, facility, url, scraper_factory)
      end

      # def perform(url = ENV["SMOKE_GYM_URL"], username = nil, password = nil, scraper_factory = ScraperFactory)
      #   Rails.logger.info("Scraping schedule for #{url}")
      #   save_schedule(url, username, password, scraper_factory)
      # end

      private

      def save_schedule(date, facility, url, scraper_factory)
        scraper = scraper_factory.build_scraper(url, username = nil, password = nil)
        get_and_process_cities(scraper, date, facility)
      rescue StandardError => e
        Rails.logger.error("Error scraping schedule for #{url}: #{e}")
      ensure
        scraper&.end_session
      end

      # def save_schedule(url, username, password, scraper_factory)
      #   scraper = scraper_factory.build_scraper(url, username, password)
      #   get_and_process_cities(scraper)
      # rescue StandardError => e
      #   Rails.logger.error("Error scraping schedule for #{url}: #{e}")
      # ensure
      #   scraper&.end_session
      # end


      def get_and_process_cities(scraper, date, facility)
        Rails.logger.debug("Scraping cities")
        scraper.scrape_cities.intersection(CITIES).each { |city| get_and_process_facilities(scraper, city, date, facility) }
      end

      def get_and_process_facilities(scraper, city, date, facility)
        Rails.logger.debug("Scraping facilities for #{city}")
        scraper.scrape_facilities(city).intersection([facility]).each { |facility| get_and_process_day_schedule(scraper, city, facility, date) }
      end

      def get_and_process_week_schedule(scraper, city, facility)
        Rails.logger.debug("Scraping week schedule for #{city} and #{facility}")
        today = Time.zone.today
        week = (today.beginning_of_week(:sunday)..today.end_of_week(:sunday))
        week.each do |day|
          get_and_process_day_schedule(scraper, city, facility, day)
        end
      end

      def get_and_process_day_schedule(scraper, city, facility, day)
        Rails.logger.debug("Scraping day schedule for #{city} #{facility} and #{day}")
        formatted_day =  I18n.l(day, format: "%b %d").capitalize
        schedule = scraper.scrape_schedule(city, facility, formatted_day)
        process_day_schedule(schedule, day)
      end

      def process_day_schedule(schedule, day)
        ActiveRecord::Base.transaction do
          schedule.each do |item|
            Rails.logger.debug("Processing schedule #{item} for #{day}")
            city = find_or_create_city(item[:city])
            add_schedule_to_city(city, day, item)
          end
        end
      end

      def find_or_create_city(city)
        Rails.logger.debug("Finding city #{city}")
        City.find_or_create_by!(name: city)
      end

      def add_schedule_to_city(city, day, item)
        Rails.logger.debug("Adding schedule to city #{city} #{day}")

        facility = find_or_create_facility(city, item[:facility])
        add_schedule_to_facility(facility, day, item)
      end

      def find_or_create_facility(city, facility)
        Rails.logger.debug("Finding facility #{facility}")

        city.facilities.find_or_create_by!(name: facility)
      end

      def add_schedule_to_facility(facility, date, item)
        Rails.logger.debug("Adding schedule #{item} to facility #{item[:facility]} #{date}")

        start_time = Time.zone.parse("#{date.to_date} #{item[:time]}")
        class_type = find_or_create_class_type(item[:activity])
        facility.schedules.find_or_create_by!(
          class_type_id: class_type.id,
          day_of_week: date.wday,
          facility: facility,
          start_time: start_time
        )
      end

      def find_or_create_class_type(activity)
        Rails.logger.debug("Finding class type #{activity}")

        ClassType.find_or_create_by!(name: activity, duration: 60)
      end
    end
  end
end
