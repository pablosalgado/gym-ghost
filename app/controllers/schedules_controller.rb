class SchedulesController < ApplicationController
  def index
    @cities = City.includes(:facilities).where(name: GymGhost::Scraper::ScrapeScheduleJob::CITIES).order(:name).all
    @facilities = @cities.first.facilities.order(:name)
    @class_types = ClassType.order(:name).all

    @selected_city = find_city || @cities.first
    @selected_facility = find_facility || @facilities.first
    @selected_class_type = find_class_type || @class_types.first

    @selected_day = params[:day].to_i
    @selected_date =  Time.current + @selected_day.days

    @schedules = fetch_schedules

    if @schedules.empty?
      GymGhost::Scraper::ScrapeScheduleJob.perform_now(
        @selected_date,
        @selected_facility.name,
        ENV.fetch("SMOKE_GYM_URL"),
        GymGhost::Scraper::ScraperFactory
      )
      @schedules = fetch_schedules
    end
  end

  private

  def fetch_schedules
    Schedule.includes(:class_type, :facility).where(
      start_time: @selected_date.beginning_of_day..@selected_date.end_of_day,
      facility: @selected_facility
    ).order(:start_time)
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
