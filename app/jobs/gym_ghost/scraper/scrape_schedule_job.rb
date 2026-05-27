module GymGhost
  module Scraper
    class ScrapeScheduleJob < ApplicationJob
      queue_as :default

      def perform(url = ENV["SMOKE_GYM_URL"], username = nil, password = nil, scraper_factory = ScraperFactory)
        Rails.logger.info("Scraping schedule for #{url}")
        save_schedule(url, username, password, scraper_factory)
      end

      private

      def save_schedule(url, username, password, scraper_factory)
        scraper = scraper_factory.build_scraper(url, username, password)
        get_and_process_cities(scraper)
      rescue StandardError => e
        Rails.logger.error("Error scraping schedule for #{url}: #{e}")
      ensure
        scraper&.end_session
      end

      def get_and_process_cities(scraper)
        Rails.logger.debug("Scraping cities")
        scraper.scrape_cities.each { |city| get_and_process_facilities(scraper, city) }
      end

      def get_and_process_facilities(scraper, city)
        Rails.logger.debug("Scraping facilities for #{city}")
        scraper.scrape_facilities(city).each { |facility| get_and_process_week_schedule(scraper, city, facility) }
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

      def add_schedule_to_facility(facility, day, item)
        Rails.logger.debug("Adding schedule #{item} to facility #{item[:facility]} #{day}")

        class_type = find_or_create_class_type(item[:activity], item[:duration])
        facility.schedules.find_or_create_by!(class_type_id: class_type.id, day_of_week: day.wday, facility: facility, start_time: item[:time])
      end

      def find_or_create_class_type(activity, duration)
        Rails.logger.debug("Finding class type #{activity}")

        ClassType.find_or_create_by!(name: activity, duration: duration.split[0].to_i)
      end
    end
  end
end
