module Api
  module V1
    class ClassTypesController < ApplicationController
      def index
        class_types = Activity.order(:name)
        if filter_params[:facility_id].present?
          facility_id = filter_params[:facility_id]
          class_types = class_types.joins(:schedule_entries).where(schedule_entries: { facility_id: }).distinct
        end

        render json: { class_types: class_types.as_json(only: %i[id name]) }
      end

      private

      def filter_params
        params.permit(:facility_id)
      end
    end
  end
end
