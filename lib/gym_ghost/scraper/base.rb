# frozen_string_literal: true

module GymGhost
  module Scraper
    class Base
      attr_reader :url, :username, :password, :driver, :wait

      def initialize(url, username, password, driver:, wait:)
        @url = url
        @username = username
        @password = password
        @driver = driver
        @wait = wait
      end

      def end_session
        @driver.quit
      end

      def self.gym_id = raise NotImplementedError, "#{self} must implement .gym_id"
      def self.register! = raise NotImplementedError, "#{self} must implement .register!"
      def end_session = @driver.quit
      def scrape_cities = raise NotImplementedError, "#{self.class} must implement #scrape_cities"
      def scrape_facilities = raise NotImplementedError, "#{self.class} must implement #scrape_facilities"
      def scrape_schedule = raise NotImplementedError, "#{self.class} must implement #scrape_schedule"
      def login = raise NotImplementedError, "#{self.class} must implement #login"
    end
  end
end
