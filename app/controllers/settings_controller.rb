class SettingsController < ApplicationController
  def show
  end

  def scrape_locations
    GymGhost::Scraper::ScrapeLocationsJob.perform_later
    redirect_to settings_path, notice: t("flash.locations_scraping_started")
  end
end
