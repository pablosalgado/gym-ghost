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

      def self.gym_id = raise NotImplementedError, "#{self} must implement .gym_id"
      def self.register! = raise NotImplementedError, "#{self} must implement .register!"
      def scrap_cities = raise NotImplementedError, "#{self.class} must implement #scrap_cities"
      def scrap_facilities = raise NotImplementedError, "#{self.class} must implement #scrap_facilities"
      def scrap_schedule = raise NotImplementedError, "#{self.class} must implement #scrap_schedule"
    end
  end
end
