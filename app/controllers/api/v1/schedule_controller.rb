module Api
  module V1
    class ScheduleController < ApplicationController
      def index
        render json: { schedule: mock_schedule }
      end

      private

      def mock_schedule
        today = Date.current
        end_date = today + 14.days

        classes = []
        (today...end_date).each do |date|
          classes.concat(classes_for_date(date))
        end

        classes
      end

      def classes_for_date(date)
        day_of_week = date.wday
        classes = []

        # Bogota classes
        classes << build_class(date, "08:00", "Yoga Flow", "Chicó Center", "Bogota")
        classes << build_class(date, "10:00", "Spin Pro", "Chicó Center", "Bogota")
        classes << build_class(date, "17:00", "HIIT Blast", "Norte Studio", "Bogota")

        # Medellin classes
        classes << build_class(date, "07:00", "Pilates Core", "El Poblado Gym", "Medellin")
        classes << build_class(date, "09:00", "Yoga Flow", "El Poblado Gym", "Medellin")
        classes << build_class(date, "18:00", "Spin Pro", "Laureles Hub", "Medellin")

        # Weekend-only classes
        if day_of_week == 0 || day_of_week == 6
          classes << build_class(date, "10:00", "HIIT Blast", "Chicó Center", "Bogota")
          classes << build_class(date, "11:00", "Pilates Core", "Laureles Hub", "Medellin")
        end

        classes
      end

      def build_class(date, time, name, facility, city)
        start_time = Time.zone.parse("#{date} #{time}").utc

        {
          id: "#{date}-#{time.parameterize}-#{name.parameterize}",
          name: name,
          start_time: start_time.iso8601,
          facility: facility,
          city: city
        }
      end
    end
  end
end
