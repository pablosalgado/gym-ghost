module Api
  module V1
    class ActivitiesController < ApplicationController
      def index
        activities = Activity.order(:name)
        activities = activities.joins(:schedule_entries)
                               .where(schedule_entries: { facility_id: filter_params[:facility_id] })
                               .distinct if filter_params[:facility_id].present?

        render json: { activities: activities.as_json(only: %i[id name]) }
      end

      private

      def filter_params
        params.permit(:facility_id)
      end
    end
  end
end
