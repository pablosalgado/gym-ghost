# frozen_string_literal: true

require "holidays"

class HolidayService
  DEFAULT_TIME_ZONE = "America/Bogota".freeze

  class << self
    def holiday?(date_or_time, region: :co, time_zone: DEFAULT_TIME_ZONE)
      resolved_date = resolve_date(date_or_time, time_zone)
      return false unless resolved_date

      cache_key = "holiday_service/#{region}/#{resolved_date}"

      memoized_cache[cache_key] ||= Rails.cache.fetch(cache_key, expires_in: 1.day) do
        holidays_on(resolved_date, region).any?
      end
    end

    def holiday_name(date_or_time, region: :co, time_zone: DEFAULT_TIME_ZONE)
      resolved_date = resolve_date(date_or_time, time_zone)
      return nil unless resolved_date

      holidays = holidays_on(resolved_date, region)
      holidays.first&.[](:name)
    end

    def clear_cache!
      Thread.current[:holiday_service_memo_cache] = nil
    end

    private

    def resolve_date(date_or_time, time_zone)
      case date_or_time
      when Date
        date_or_time
      when Time, DateTime, ActiveSupport::TimeWithZone
        date_or_time.in_time_zone(time_zone).to_date
      when String
        Date.parse(date_or_time)
      else
        nil
      end
    rescue ArgumentError
      nil
    end

    def holidays_on(date, region)
      Holidays.on(date, region, :observed)
    end

    def memoized_cache
      Thread.current[:holiday_service_memo_cache] ||= {}
    end
  end
end
