# frozen_string_literal: true

module Partner
  # Raised when fetching class-type schedules from the downstream gym partner API
  # fails (non-success status, malformed body, or missing required fields).
  class ClassTypesError < StandardError
    def initialize(message = "Partner class types fetch failed")
      super
    end
  end
end
