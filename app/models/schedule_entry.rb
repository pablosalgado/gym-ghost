class ScheduleEntry < ApplicationRecord
  belongs_to :facility
  belongs_to :class_type
  has_many :booking_requests, dependent: :restrict_with_error

  validates :date, presence: true
  validates :start_time, presence: true
end
