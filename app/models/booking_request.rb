class BookingRequest < ApplicationRecord
  belongs_to :gym_member
  belongs_to :schedule_entry

  enum :status, { pending: 0, booked: 1, failed: 2 }

  validates :booking_window_opens_at, presence: true
  validates :status, presence: true
end
