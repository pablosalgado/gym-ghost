class Facility < ApplicationRecord
  belongs_to :city
  has_many :schedules, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
end
