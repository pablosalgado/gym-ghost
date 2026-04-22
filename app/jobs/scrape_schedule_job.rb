class ScrapeScheduleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info("Scraping schedule ...")
  end
end
