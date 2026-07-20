class ScheduleEntry < ApplicationRecord
  belongs_to :facility
  belongs_to :activity

  validates :date, presence: true
  validates :start_time, presence: true
end
