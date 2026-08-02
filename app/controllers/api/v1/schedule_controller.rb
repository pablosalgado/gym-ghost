module Api
  module V1
    class ScheduleController < ApplicationController
      def index
        entries = upcoming_entries

        render json: {
          schedule: serialize_entries(entries),
          class_types: class_types_for(entries)
        }
      end

      private

      def schedule_params
        params.permit(:date, :facility_id)
      end

      def upcoming_entries
        facility = Facility.find_by(id: schedule_params[:facility_id])
        entries = Partner::ActivitiesService.new.fetch(
          facility: facility,
          date: schedule_params[:date]
        )

        entries.select { |entry| entry.start_time >= Time.current }.sort_by(&:start_time)
      end

      def serialize_entries(entries)
        booking_requests_by_entry = booking_requests_for(entries)

        entries.map do |entry|
          {
            id: entry.id,
            activity_name: entry.class_type.name,
            activity_id: entry.class_type_id,
            facility_id: entry.facility_id,
            starts_at: entry.start_time.utc.iso8601,
            booking_request: serialize_booking_request(booking_requests_by_entry[entry.id])
          }
        end
      end

      def class_types_for(entries)
        entries.map(&:class_type).uniq(&:id).map { |class_type| { id: class_type.id, name: class_type.name } }
      end

      def serialize_booking_request(booking_request)
        return nil unless booking_request

        {
          id: booking_request.id,
          status: booking_request.status,
          booking_window_opens_at: booking_request.booking_window_opens_at.utc.iso8601
        }
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
