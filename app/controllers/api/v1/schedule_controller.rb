module Api
  module V1
    class ScheduleController < ApplicationController
      before_action :validate_schedule_request

      def index
        entries = upcoming_entries

        render json: {
          schedule: serialize_entries(entries),
          class_types: class_types_for(entries)
        }
      end

      private

      def schedule_params
        params.permit(:date, :city_id, :facility_id)
      end

      def validate_schedule_request
        requested_params = schedule_params
        missing_params = %i[city_id facility_id date].select { |key| requested_params[key].blank? }
        return render_scope_error("#{missing_params.join(" and ")} #{missing_params.one? ? "is" : "are"} required.") if missing_params.any?

        city = City.find_by(id: requested_params[:city_id])
        return render_scope_error("City not found.") unless city

        facility = Facility.find_by(id: requested_params[:facility_id])
        return render_scope_error("Facility not found.") unless facility
        return render_scope_error("Facility does not belong to the requested city.") unless facility.city_id == city.id

        @facility = facility
        @date = requested_params[:date]
      end

      def render_scope_error(detail)
        render json: {
          errors: [ { status: 422, title: "Validation Failed", detail: detail } ]
        }, status: :unprocessable_entity
      end

      def upcoming_entries
        entries = Partner::ActivitiesService.new.fetch(
          facility: @facility,
          date: @date
        )

        entries.select do |entry|
          entry.facility_id == @facility.id &&
            entry.date.to_s == @date &&
            entry.start_time >= Time.current
        end.sort_by(&:start_time)
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
