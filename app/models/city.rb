class City < ApplicationRecord
  has_many :facilities, dependent: :destroy

  validates :city_name, presence: true, uniqueness: true
end
