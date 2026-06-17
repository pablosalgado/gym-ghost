class ScrapeLog < ApplicationRecord
  enum :status, { completed: "completed", failed: "failed" }

  validates :facility, presence: true
  validates :date, presence: true
  validates :facility, uniqueness: { scope: :date }
end
