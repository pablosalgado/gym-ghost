class SchedulesController < ApplicationController
  def index
    @cities = City.includes(:facilities)
                  .where(name: GymGhost::Scraper::ScrapeScheduleJob::CITIES)
                  .order(:name)
                  .all

    GymGhost::Scraper::ScrapeLocationsJob.perform_now(
      Rails.application.credentials.dig(:gym, :url),
      GymGhost::Scraper::ScraperFactory
    ) if @cities.empty?

    @facilities = @cities.first.facilities.order(:name)
    @class_types = ClassType.order(:name).all

    @selected_city = find_city || @cities.first
    @selected_facility = find_facility || @facilities.first
    @selected_class_type = find_class_type

    @selected_day = params[:day].to_i
    @selected_date =  Time.current + @selected_day.days

    @schedules = fetch_schedules

    if @schedules.empty?
      scrape_if_needed
      @schedules = fetch_schedules
    end

    @programmed_schedule_ids = Current.user.programmed_classes
      .where(schedule_id: @schedules.map(&:id))
      .pluck(:schedule_id)
  end

  private

  def scrape_if_needed
    return unless @selected_facility

    date = @selected_date.to_date
    return if ScrapeLog.exists?(facility: @selected_facility.name, date: date)

    ScrapeLog.create!(facility: @selected_facility.name, date: date)

    GymGhost::Scraper::ScrapeScheduleJob.perform_now(
      date,
      @selected_facility.name,
      Rails.application.credentials.dig(:gym, :url),
      GymGhost::Scraper::ScraperFactory
    )
  rescue StandardError => e
    Rails.logger.error("Error scraping schedule: #{e}")
    ScrapeLog.find_by(facility: @selected_facility.name, date: date)&.update!(status: "failed", error_message: e.message)
  end

  def fetch_schedules
    scope = Schedule.includes(:class_type, :facility)
    lower_bound = @selected_day == 0 ? Time.current : @selected_date.beginning_of_day
    scope = scope.where(start_time: lower_bound..@selected_date.end_of_day)
    scope = scope.where(facility: @selected_facility)
    scope = scope.where(class_type: @selected_class_type) if @selected_class_type.present?
    scope = scope.order(:start_time)
    scope
  end

  def find_city
    City.find(params[:city]) if params[:city].present?
  end

  def find_facility
    Facility.find(params[:facility]) if params[:facility].present?
  end

  def find_class_type
    ClassType.find(params[:activity]) if params[:activity].present?
  end
end
