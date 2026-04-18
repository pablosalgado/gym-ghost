class Schedule < ApplicationRecord
  belongs_to :facility
  belongs_to :class_type

  enum :day_of_week, { sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6 }

  validates :start_time, presence: true
  validates :day_of_week, presence: true
end
