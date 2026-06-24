module GymGhost
  module Scraper
    class MissingCredentialsError < StandardError
      def initialize(message = "Missing credentials for gym scraping. Please check your Rails credentials.")
        super(message)
      end
    end
  end
end
