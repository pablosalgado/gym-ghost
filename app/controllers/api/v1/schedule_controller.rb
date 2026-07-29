module Api
  module V1
    class ScheduleController < ApplicationController
      def index
        date = schedule_params[:date] || Time.zone.today.to_s
        entries = ScheduleEntry.includes(:class_type, :facility).where(date: date)
        entries = entries.where(facility_id: schedule_params[:facility_id]) if schedule_params[:facility_id].present?
        entries = entries.where(start_time: Time.current..)
        entries = entries.order(:start_time).to_a

        if entries.empty? && schedule_params[:facility_id].present?
          FetchScheduleEntriesJob.perform_later(schedule_params[:facility_id], date)
        end

        booking_requests_by_entry = booking_requests_for(entries)

        class_types = entries.map(&:class_type).uniq(&:id).map { |ct| { id: ct.id, name: ct.name } }

        schedule = entries.map do |entry|
          br = booking_requests_by_entry[entry.id]
          {
            id: entry.id,
            activity_name: entry.class_type.name,
            activity_id: entry.class_type_id,
            facility_id: entry.facility_id,
            starts_at: entry.start_time.utc.iso8601,
            booking_request: br ? { id: br.id, status: br.status, booking_window_opens_at: br.booking_window_opens_at.utc.iso8601 } : nil
          }
        end

        render json: { schedule: schedule, class_types: class_types }
      end

      private

      def schedule_params
        params.permit(:date, :facility_id)
      end

      def booking_requests_for(entries)
        return {} if entries.empty?

        gym_member = current_gym_member
        return {} unless gym_member

        BookingRequest.where(
          gym_member: gym_member,
          schedule_entry_id: entries.map(&:id)
        ).index_by(&:schedule_entry_id)
      end

      def current_gym_member
        GymMember.find_by(email: current_user.email)
      end
    end
  end
end
