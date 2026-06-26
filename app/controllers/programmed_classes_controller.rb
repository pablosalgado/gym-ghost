class ProgrammedClassesController < ApplicationController
  def index
    @programmed_classes = Current.user.programmed_classes
      .includes(schedule: [ :class_type, :facility ])
      .upcoming
  end

  def create
    schedule = Schedule.find(params[:schedule_id])
    pc = Current.user.programmed_classes.find_or_initialize_by(schedule: schedule)

    if pc.canceled? || pc.failed?
      pc.status = :programmed
      pc.save!
    elsif pc.new_record?
      pc.status = :programmed
      pc.save!
      GymGhost::Scraper::ReserveClassJob
        .set(wait_until: schedule.start_time - 24.hours)
        .perform_later(pc.id)
    elsif pc.programmed?
      pc.update!(status: :canceled)
    end

    redirect_back fallback_location: schedules_path
  end

  def destroy
    pc = Current.user.programmed_classes.find(params[:id])
    pc.update!(status: :canceled)

    redirect_back fallback_location: programmed_classes_path
  end
end
