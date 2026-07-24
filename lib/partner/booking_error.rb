# frozen_string_literal: true

module Partner
  # Raised when booking a gym session through the downstream partner API
  # fails (non-OK status, malformed body, or partner-specific error responses).
  class BookingError < StandardError
    def initialize(message = "Partner booking failed")
      super
    end
  end
end
