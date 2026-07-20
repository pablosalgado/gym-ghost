# frozen_string_literal: true

# Base class for all Active Job jobs in Gym Ghost.
# Inherits Rails 8.1 defaults (Solid Queue in production, async in
# development/test). Subclasses set `queue_as` and `perform` logic.
class ApplicationJob < ActiveJob::Base
end
