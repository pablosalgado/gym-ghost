# frozen_string_literal: true

class HolidayScheduleRefreshJob < ApplicationJob
  queue_as :default

  # Wrapped by Active Job's retry/discards behavior is intentionally NOT
  # configured here: the service is idempotent and a transient failure
  # should surface in the dispatcher logs rather than silently retry
  # through midnights. Add explicit retry on a future case-by-case basis
  # only.
  def perform
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
      process_facility(facility, tomorrow)
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

  def process_facility(facility, date)
    service = Partner::ActivitiesService.new
    returned = service.fetch(facility: facility, date: date)

    update_activ_config_ids(facility, date, returned)

    entry_count = ScheduleEntry.where(facility: facility, date: date).count
    Rails.logger.info(log_message(date, "facility #{facility.id} (#{facility.name}): #{entry_count} entries refreshed"))
  rescue Partner::ActivitiesError => e
    Rails.logger.warn(log_message(date, "facility #{facility.id} (#{facility.name}) failed: #{e.message}"))
  end

  def update_activ_config_ids(facility, date, returned_entries)
    ScheduleEntry.where(facility: facility, date: date).find_each do |entry|
      matching = returned_entries.find do |returned|
        returned.class_type_id == entry.class_type_id &&
          returned.start_time == entry.start_time &&
          returned.activ_config_id != entry.activ_config_id
      end
      next unless matching

      entry.update!(activ_config_id: matching.activ_config_id)
    end
  end

  def log_message(date, detail)
    "[#{self.class.name}] #{date} — #{detail}"
  end
end
