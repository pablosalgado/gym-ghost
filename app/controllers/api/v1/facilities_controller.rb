module Api
  module V1
    class FacilitiesController < ApplicationController
      def index
        facilities = Facility.order(:display_name)
        facilities = facilities.where(city_id: filter_params[:city_id]) if filter_params[:city_id].present?

        render json: { facilities: facilities.as_json(only: [ :id, :display_name, :city_id ]) }
      end

      private

      def filter_params
        params.permit(:city_id)
      end
    end
  end
end
