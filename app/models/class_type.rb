class ClassType < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
  validates :duration, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 60  }
end
