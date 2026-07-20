class Facility < ApplicationRecord
  belongs_to :city

  validates :external_id, presence: true, uniqueness: true
end
