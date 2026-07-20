# frozen_string_literal: true

module Partner
  # Raised when fetching branches from the downstream gym partner API
  # fails (non-success status, malformed body, or missing required fields).
  class FacilitiesSyncError < StandardError
    def initialize(message = "Partner facilities sync failed")
      super
    end
  end
end
