# frozen_string_literal: true

require "httparty"
require "json"

module Partner
  # Fetches gym activity schedules from the downstream partner API
  # and upserts ClassType and ScheduleEntry records.
  class ActivitiesService
    include HTTParty

    format :json
    headers "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:152.0) Gecko/20100101 Firefox/152.0",
            "Accept"          => "application/json, text/plain, */*",
            "Accept-Language" => "en-US,en;q=0.9",
            "Accept-Encoding" => "gzip, deflate, br, zstd",
            "X-Client-Origin" => "WEB",
            "Connection"      => "keep-alive",
            "Sec-Fetch-Dest"  => "",
            "Sec-Fetch-Mode"  => "cors",
            "Sec-Fetch-Site"  => "cross-site"

    ACTIVITIES_PATH = "/api/v1/activities/generic"

    NON_HOLIDAY_SUNDAY_WALK_BACK_LIMIT = 7

    def initialize; end

    # Fetches activities for the given facility and date.
    #
    # facility - a Facility record whose evo_token is sent as token_branch
    # date     - a Date object or a String in YYYY-MM-DD format
    #
    # Returns an array of ScheduleEntry records.
    # Raises Partner::ActivitiesError on any failure.
    def fetch(facility:, date:)
      resolved_date = date.is_a?(String) ? Date.parse(date) : date
      cache_key = "schedule_load:#{facility.id}:#{resolved_date}"

      unless Rails.cache.write(cache_key, true, unless_exist: true, expires_in: 5.minutes)
        return ScheduleEntry.includes(:class_type, :facility).where(facility: facility, date: resolved_date).to_a
      end

      begin
        local_entries = ScheduleEntry.includes(:class_type, :facility).where(facility: facility, date: resolved_date).to_a
        return local_entries if local_entries.any?

        response = request_activities(facility, date)
        payload = parse_payload(response)

        raise ActivitiesError, error_detail(response, payload) unless response.success?
        raise ActivitiesError, error_detail(response, payload) if payload["status"] == "ERROR"

        data = payload["data"]
        raise ActivitiesError, "Missing data array in partner response" unless data.is_a?(Array)

        holiday_dates = Set.new

        entries = data.each_with_object([]) do |item, result|
          next if item["activity_name"].blank?

          class_type = ClassType.find_or_create_by!(name: item["activity_name"])

          facility_record = Facility.find_by(external_id: item["branch_id"])
          next if facility_record.nil?

          start_time = item["start_time"]
          entry_date = resolve_entry_date(item, date)

          if HolidayService.holiday?(entry_date)
            holiday_dates << [ facility_record.id, entry_date ]
            next
          end

          entry = ScheduleEntry.find_or_initialize_by(
            facility: facility_record,
            class_type: class_type,
            start_time: start_time
          )
          entry.date = entry_date
          entry.partner_activity_id = item["activity_id"]
          entry.activ_config_id = item["activ_config_id"]
          entry.save!

          result << entry
        end

        backfill_holidays(holiday_dates)

        entries
      ensure
        Rails.cache.delete(cache_key)
      end
    end

    private

    def resolve_entry_date(item, fallback_date)
      raw = item["date"] || fallback_date
      raw.is_a?(String) ? Date.parse(raw) : raw
    end

    def backfill_holidays(holiday_dates)
      holiday_dates.each do |facility_id, holiday_date|
        source_date = find_source_sunday(holiday_date)
        next unless source_date

        sunday_entries = ScheduleEntry.where(facility_id: facility_id, date: source_date)
        next if sunday_entries.none?

        sunday_entries.each do |sunday_entry|
          holiday_start = same_time_on_date(sunday_entry.start_time, holiday_date)

          entry = ScheduleEntry.find_or_initialize_by(
            facility_id: facility_id,
            class_type: sunday_entry.class_type,
            start_time: holiday_start
          )
          entry.date = holiday_date
          entry.partner_activity_id = sunday_entry.partner_activity_id
          entry.activ_config_id = sunday_entry.activ_config_id
          entry.save!
        end
      end
    end

    def find_source_sunday(holiday_date)
      candidate = holiday_date.prev_occurring(:sunday)
      attempts = 0

      while attempts < NON_HOLIDAY_SUNDAY_WALK_BACK_LIMIT
        return candidate unless HolidayService.holiday?(candidate)

        candidate = candidate.prev_day
        attempts += 1
      end

      nil
    end

    def same_time_on_date(datetime, new_date)
      datetime.change(year: new_date.year, month: new_date.month, day: new_date.day)
    end

    def request_activities(facility, date)
      activities_date = date.is_a?(String) ? date : date.iso8601

      self.class.get(
        "#{ENV.fetch("PARTNER_API_BASE_URL")}#{ACTIVITIES_PATH}",
        query: {
          timezone: "America/Bogota",
          token_branch: facility.evo_token,
          activities_date: activities_date,
          partner_name: "EVO",
          show_full_week: true
        },
        headers: {
          "Authorization" => ENV.fetch("PARTNER_ACTIVITIES_TOKEN"),
          "Origin"        => ENV.fetch("PARTNER_AUTH_ORIGIN"),
          "Referer"       => ENV.fetch("PARTNER_AUTH_REFERER")
        }
      )
    end

    def parse_payload(response)
      parsed = response.parsed_response
      raise ActivitiesError, "Malformed partner response" unless parsed.is_a?(Hash)

      parsed
    end

    def error_detail(response, payload = nil)
      payload ||= begin
        parsed = response.parsed_response
        parsed.is_a?(Hash) ? parsed : nil
      rescue StandardError
        nil
      end

      if payload
        if payload["errors"].is_a?(Array) && payload["errors"].any?
          return payload["errors"].join(", ")
        end

        return payload["error"] if payload["error"].present?
        return payload["message"] if payload["message"].present?
      end

      "Partner activities fetch failed (HTTP #{response.code})"
    end
  end
end
