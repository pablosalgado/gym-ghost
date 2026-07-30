module Api
  module V1
    class BookingRequestsController < ApplicationController
      def create
        schedule_entry = ScheduleEntry.find(booking_request_params[:schedule_entry_id])

        if schedule_entry.start_time.past?
          return render json: {
            errors: [ { status: 422, title: "Validation Failed", detail: "Schedule entry is in the past." } ]
          }, status: :unprocessable_entity
        end

        created_count = 0
        first_booking_request = nil

        GymMember.all.each do |gym_member|
          next if duplicate_booking_request?(gym_member, schedule_entry)

          booking_window_opens_at = calculate_booking_window(schedule_entry)

          booking_request = BookingRequest.new(
            gym_member: gym_member,
            schedule_entry: schedule_entry,
            status: :pending,
            booking_window_opens_at: booking_window_opens_at
          )

          booking_request.save!

          if booking_window_opens_at.past?
            BookingRequestJob.perform_later(booking_request.id)
          else
            BookingRequestJob.set(wait_until: booking_window_opens_at).perform_later(booking_request.id)
          end

          first_booking_request ||= booking_request
          created_count += 1
        end

        if created_count.positive?
          render json: {
            booking_request: {
              id: first_booking_request.id,
              status: first_booking_request.status,
              booking_window_opens_at: first_booking_request.booking_window_opens_at.utc.iso8601,
              schedule_entry_id: first_booking_request.schedule_entry_id
            },
            created_count: created_count
          }, status: :created
        else
          head :no_content
        end
      end

      def destroy
        BookingRequest.find(params[:id]).destroy!
        head :no_content
      end

      private

      def booking_request_params
        params.permit(:schedule_entry_id)
      end

      def calculate_booking_window(schedule_entry)
        schedule_entry.start_time - 24.hours
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
