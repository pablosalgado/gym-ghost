module Api
  module V1
    class FacilitiesController < ApplicationController
      def index
        facilities = Facility.order(:display_name)
        facilities = facilities.where(city_id: params[:city_id]) if params[:city_id].present?

        render json: { facilities: facilities.as_json(only: [ :id, :display_name, :city_id ]) }
      end
    end
  end
end
