# frozen_string_literal: true

# Syncs local City and Facility records from the downstream gym partner
# branches API. Delegates all I/O and persistence to Partner::FacilitiesService.
#
# Scheduled daily at 00:00 UTC via Solid Queue recurring tasks
# (see config/recurring.yml). The Solid Queue supervisor process
# (`bin/jobs`) dispatches the schedule; nothing else enqueues this job
# under normal operation.
class SyncFacilitiesJob < ApplicationJob
  queue_as :default

  # Wrapped by Active Job's retry/discards behavior is intentionally NOT
  # configured here: the service is idempotent (find_or_create_by! per row)
  # and a transient failure should surface in the dispatcher logs rather
  # than silently retry through midnights. Add explicit retry on a future
  # case-by-case basis only.
  def perform
    Partner::FacilitiesService.new.sync
  end
end
