# frozen_string_literal: true

module Partner
  # Raised when booking through the downstream gym partner API fails.
  class BookingError < StandardError
    def initialize(message = "Partner booking failed")
      super
    end
  end
end
