# frozen_string_literal: true

module GymGhost
  module Scraper
    class Registry
      @scrapers = {}

      class << self
        def register(klass)
          @scrapers[klass.gym_id] = klass
        end
      end
    end
  end
end
