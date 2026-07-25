module Api
  module V1
    class CitiesController < ApplicationController
      def index
        # Run the partner facilities sync inline on a cold DB so the first
        # browser request returns populated data instead of `[]` while a
        # background job is still in flight. The job is idempotent
        # (find_or_create_by! per row), so concurrent first requests are safe.
        SyncFacilitiesJob.perform_now if City.count.zero?

        cities = City.order(:city_name)
        render json: { cities: cities.as_json(only: [ :id, :city_name ]) }
      end
    end
  end
end
