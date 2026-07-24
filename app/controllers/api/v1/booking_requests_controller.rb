module Api
  module V1
    class BookingRequestsController < ApplicationController
      DEFAULT_TIME_ZONE = "America/Bogota".freeze

      def create
        schedule_entry = ScheduleEntry.find(booking_request_params[:schedule_entry_id])

        if schedule_entry.start_time.past?
          return render json: {
            errors: [ { status: 422, title: "Validation Failed", detail: "Schedule entry is in the past." } ]
          }, status: :unprocessable_entity
        end

        gym_member = GymMember.find_by!(email: current_user.email)

        if duplicate_booking_request?(gym_member, schedule_entry)
          return render json: {
            errors: [ { status: 409, title: "Conflict", detail: "A booking request already exists for this schedule entry." } ]
          }, status: :conflict
        end

        booking_window_opens_at = calculate_booking_window(schedule_entry)

        booking_request = BookingRequest.new(
          gym_member: gym_member,
          schedule_entry: schedule_entry,
          status: :pending,
          booking_window_opens_at: booking_window_opens_at
        )

        booking_request.save!

        BookingRequestJob.set(wait_until: booking_window_opens_at).perform_later(booking_request.id)

        render json: {
          booking_request: {
            id: booking_request.id,
            status: booking_request.status,
            booking_window_opens_at: booking_request.booking_window_opens_at.utc.iso8601,
            schedule_entry_id: booking_request.schedule_entry_id
          }
        }, status: :created
      end

      private

      def booking_request_params
        params.permit(:schedule_entry_id)
      end

      def calculate_booking_window(schedule_entry)
        zone = Time.find_zone!(DEFAULT_TIME_ZONE)
        schedule_entry.start_time.in_time_zone(zone) - 24.hours
      end

      def duplicate_booking_request?(gym_member, schedule_entry)
        BookingRequest.where(
          gym_member: gym_member,
          schedule_entry: schedule_entry,
          status: [ :pending, :booked ]
        ).exists?
      end
    end
  end
end
