class ScheduleEntry < ApplicationRecord
  belongs_to :facility
  belongs_to :class_type

  validates :date, presence: true
  validates :start_time, presence: true
end
