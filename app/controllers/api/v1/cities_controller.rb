module Api
  module V1
    class CitiesController < ApplicationController
      def index
        SyncFacilitiesJob.perform_later if City.count.zero?

        cities = City.order(:city_name)
        render json: { cities: cities.as_json(only: [ :id, :city_name ]) }
      end
    end
  end
end
