class ProgrammedClassesController < ApplicationController
  def index
    @programmed_classes = Current.user.programmed_classes
      .includes(schedule: [ :class_type, :facility ])
      .upcoming
  end

  def create
    schedule = Schedule.find(params[:schedule_id])
    programmed_class = Current.user.programmed_classes.find_or_initialize_by(schedule: schedule)

    if programmed_class.new_record? || programmed_class.canceled? || programmed_class.failed?
      programmed_class.status = :programmed
      programmed_class.save!
      program_class(programmed_class, schedule)
    elsif programmed_class.programmed?
      programmed_class.update!(status: :canceled)
    end

    redirect_back fallback_location: schedules_path
  end

  def destroy
    pc = Current.user.programmed_classes.find(params[:id])
    pc.update!(status: :canceled)

    redirect_back fallback_location: programmed_classes_path
  end

  private

  def program_class(programmed_class, schedule)
    schedule.start_time - Time.zone.now <= 24.hours ?
      program_class_now(programmed_class) :
      program_class_later(programmed_class, schedule)
  end

  def program_class_now(programmed_class)
    GymGhost::Scraper::ReserveClassJob
      .perform_later(programmed_class.id)
  end

  def program_class_later(programmed_class, schedule)
    GymGhost::Scraper::ReserveClassJob
      .set(wait_until: schedule.start_time - 24.hours)
      .perform_later(programmed_class.id)
  end
end
