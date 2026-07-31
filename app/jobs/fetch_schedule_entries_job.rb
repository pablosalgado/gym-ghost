# frozen_string_literal: true

# Lazily populates ScheduleEntry records for a given facility and date
# via the downstream gym partner activities API.
#
# Enqueued by ScheduleController when no cached entries exist for a
# requested facility+date combination. Delegates all I/O and persistence
# to Partner::ActivitiesService.
#
# Idempotent by construction: ActivitiesService.fetch uses
# find_or_create_by! throughout, so multiple enqueues for the same
# facility+date are harmless.
class FetchScheduleEntriesJob < ApplicationJob
  queue_as :default

  # Wrapped by Active Job's retry/discards behavior is intentionally NOT
  # configured here: the service is idempotent (find_or_create_by! per row)
  # and a transient failure should be logged rather than silently retried.
  # The next user request for the same facility+date will re-trigger the
  # cache-miss enqueue naturally.
  def perform(facility_id, date)
    facility = Facility.find(facility_id)
    Partner::ActivitiesService.new.fetch(facility: facility, date: date)
  rescue Partner::ActivitiesError => e
    Rails.logger.warn(
      "FetchScheduleEntriesJob failed for facility=#{facility_id} " \
      "date=#{date}: #{e.message}"
    )
  end
end
