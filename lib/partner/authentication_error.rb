# frozen_string_literal: true

module Partner
  # Raised when authentication against the downstream gym partner API
  # fails (non-success status, malformed body, or missing tokens).
  class AuthenticationError < StandardError
    def initialize(message = "Partner authentication failed")
      super
    end
  end
end
