module Api
  module V1
    class ScheduleController < ApplicationController
      def index
        date = filter_params[:date].presence || Time.zone.today.to_s
        entries = ScheduleEntry.includes(:activity).where(date:)
        entries = entries.where(facility_id: filter_params[:facility_id]) if filter_params[:facility_id].present?

        render json: {
          schedule: entries.map { |e|
            {
              id: e.id,
              activity_name: e.activity.name,
              activity_id: e.activity_id,
              facility_id: e.facility_id,
              starts_at: e.start_time.iso8601(3)
            }
          }
        }
      end

      private

      def filter_params
        params.permit(:date, :facility_id)
      end
    end
  end
end
