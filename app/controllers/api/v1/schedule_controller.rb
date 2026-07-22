module Api
  module V1
    class ScheduleController < ApplicationController
      def index
        entries = ScheduleEntry.includes(:activity, :facility)
        entries = entries.where(date: params[:date]) if params[:date].present?
        entries = entries.where(facility_id: params[:facility_id]) if params[:facility_id].present?

        render json: {
          schedule: entries.map { |entry|
            {
              id: entry.id,
              name: entry.activity.name,
              facility_id: entry.facility_id,
              city_id: entry.facility.city_id,
              starts_at: entry.start_time.iso8601,
              duration_minutes: 60
            }
          }
        }
      end
    end
  end
end
