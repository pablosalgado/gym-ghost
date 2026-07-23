module Api
  module V1
    class ScheduleController < ApplicationController
      DEFAULT_TIME_ZONE = "America/Bogota".freeze

      def index
        date = schedule_params[:date] || today_in_zone
        entries = ScheduleEntry.includes(:class_type, :facility).where(date: date)
        entries = entries.where(facility_id: schedule_params[:facility_id]) if schedule_params[:facility_id].present?
        entries = entries.order(:start_time).to_a

        if entries.empty? && schedule_params[:facility_id].present?
          FetchScheduleEntriesJob.perform_later(schedule_params[:facility_id], date)
        end

        class_types = entries.map(&:class_type).uniq(&:id).map { |ct| { id: ct.id, name: ct.name } }

        schedule = entries.map do |entry|
          {
            id: entry.id,
            activity_name: entry.class_type.name,
            activity_id: entry.class_type_id,
            facility_id: entry.facility_id,
            starts_at: entry.start_time.utc.iso8601
          }
        end

        render json: { schedule: schedule, class_types: class_types }
      end

      private

      def today_in_zone
        Time.find_zone!(DEFAULT_TIME_ZONE).today.to_s
      end

      def schedule_params
        params.permit(:date, :facility_id)
      end
    end
  end
end
