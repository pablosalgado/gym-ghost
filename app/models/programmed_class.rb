class ProgrammedClass < ApplicationRecord
  belongs_to :schedule
  belongs_to :user

  enum :status, { programmed: "programmed", reserved: "reserved", canceled: "canceled", failed: "failed" }

  validates :status, presence: true
  validates :schedule_id, uniqueness: { scope: :user_id }

  delegate :start_time, :class_type, :facility, to: :schedule

  scope :upcoming, -> { joins(:schedule).where(schedules: { start_time: Time.current.. }).order("schedules.start_time") }
end
