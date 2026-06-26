module GymGhost
  module Scraper
    class ReserveClassJob < ApplicationJob
      queue_as :default

      def perform(programmed_class_id)
        pc = ProgrammedClass.find(programmed_class_id)
        return unless pc.programmed?

        schedule = pc.schedule
        url = Rails.application.credentials.dig(:gym, :url)
        username = Rails.application.credentials.dig(:gym, :username)
        password = Rails.application.credentials.dig(:gym, :password)

        scraper = ScraperFactory.build_scraper(url, username, password)
        city = schedule.facility.city.name
        facility = schedule.facility.name
        date = schedule.start_time.to_date
        time = schedule.start_time.strftime("%H:%M")

        if scraper.reserve_class(city, facility, date, time)
          pc.update!(status: :reserved)
        else
          pc.update!(status: :failed)
        end
      ensure
        scraper&.end_session
      end
    end
  end
end
