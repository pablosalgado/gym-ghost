class Activity < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :schedule_entries, dependent: :destroy
end
