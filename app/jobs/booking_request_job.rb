# frozen_string_literal: true

# Processes a BookingRequest when its booking window opens.
# Enqueued by BookingRequestsController with Active Job's
# `wait_until:` set to the booking window open time.
#
# Currently a placeholder — the actual partner API call will be
# implemented in a follow-up issue.
class BookingRequestJob < ApplicationJob
  queue_as :default

  def perform(booking_request_id)
    # Placeholder: partner API integration will go here.
    # See issue #163 for the implementation.
  end
end
