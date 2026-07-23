# frozen_string_literal: true

module Partner
  # Raised when fetching activity schedules from the downstream gym partner API
  # fails (non-success status, malformed body, or missing required fields).
  class ActivitiesError < StandardError
    def initialize(message = "Partner activities fetch failed")
      super
    end
  end
end
