module Api
  module V1
    class ClassTypesController < ApplicationController
      def index
        class_types = ClassType.order(:name)
        class_types = class_types.joins(:schedule_entries)
                                 .where(schedule_entries: { facility_id: filter_params[:facility_id] })
                                 .distinct if filter_params[:facility_id].present?

        render json: { activities: class_types.as_json(only: [ :id, :name ]) }
      end

      private

      def filter_params
        params.permit(:facility_id)
      end
    end
  end
end
