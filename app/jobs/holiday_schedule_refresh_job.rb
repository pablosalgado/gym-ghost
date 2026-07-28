# frozen_string_literal: true

# Refreshes schedule entries ahead of Colombian holidays so that booking
# windows open with correct activ_config_id values from the partner API.
#
# Scheduled daily at 05:05 UTC (00:05 America/Bogota) via Solid Queue
# recurring tasks (see config/recurring.yml). The job checks whether the
# next calendar day (in America/Bogota) is a Colombian holiday; if it is,
# it fetches fresh partner data for every facility that has a booking
# request on that date.
#
# The job is idempotent — running it multiple times for the same date is
# safe. ScheduleEntry records are upserted (find_or_initialize_by) and
# holiday-backfilled by Partner::ActivitiesService, so duplicate runs only
# revalidate existing data.
class HolidayScheduleRefreshJob < ApplicationJob
  queue_as :default

  # Wrapped by Active Job's retry/discards behavior is intentionally NOT
  # configured here: the service is idempotent and a transient failure
  # should surface in the dispatcher logs rather than silently retry
  # through midnights. Add explicit retry on a future case-by-case basis
  # only.
  def perform
    # The recurring schedule fires at 05:05 UTC (00:05 America/Bogota),
    # so the next calendar day in UTC is also the next day in Colombia.
    tomorrow = Time.current.tomorrow.to_date

    unless HolidayService.holiday?(tomorrow)
      Rails.logger.info(log_message(tomorrow, "not a holiday — nothing to refresh"))
      return
    end

    Rails.logger.info(log_message(tomorrow, "holiday detected — refreshing schedules"))

    facility_ids = booking_request_facility_ids(tomorrow)

    if facility_ids.empty?
      Rails.logger.info(log_message(tomorrow, "no booking requests — nothing to refresh"))
      return
    end

    facilities = Facility.where(id: facility_ids)
    Rails.logger.info(log_message(tomorrow, "refreshing #{facilities.count} facilities"))

    facilities.find_each do |facility|
      refresh_facility(facility, tomorrow)
    end

    Rails.logger.info(log_message(tomorrow, "completed"))
  end

  private

  def booking_request_facility_ids(date)
    BookingRequest
      .joins(:schedule_entry)
      .where(schedule_entries: { date: date })
      .distinct
      .pluck(:"schedule_entries.facility_id")
  end

  def refresh_facility(facility, date)
    service = Partner::ActivitiesService.new
    service.fetch(facility: facility, date: date)

    entry_count = ScheduleEntry.where(facility: facility, date: date).count
    Rails.logger.info(log_message(date, "facility #{facility.id} (#{facility.name}): #{entry_count} entries refreshed"))
  rescue Partner::ActivitiesError => e
    Rails.logger.warn(log_message(date, "facility #{facility.id} (#{facility.name}) failed: #{e.message}"))
  end

  def log_message(date, detail)
    "[#{self.class.name}] #{date} — #{detail}"
  end
end
