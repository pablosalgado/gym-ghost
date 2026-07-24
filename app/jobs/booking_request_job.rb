# frozen_string_literal: true

# Executes a single booking request by calling the downstream partner API
# via Partner::BookingService and recording the outcome.
#
# Designed to be enqueued at the precise booking-window opening time.
# One job = one booking attempt.
#
# Idempotent: skips if the request is already booked (no double-booking).
# Does NOT retry on failure — one attempt per enqueue.
class BookingRequestJob < ApplicationJob
  queue_as :default

  def perform(booking_request_id)
    request = BookingRequest.find(booking_request_id)

    # Idempotent: skip already-booked requests
    return if request.booked?

    result = Partner::BookingService.new(gym_member: request.gym_member)
                                    .book(schedule_entry: request.schedule_entry)

    request.update!(
      status: :booked,
      partner_confirmation_id: result[:confirmation_id]
    )
  rescue Partner::BookingError => e
    request.update!(
      status: :failed,
      error_message: e.message
    )
  end
end
