FactoryBot.define do
  factory :class_type do
    sequence(:name) { |n| "Spinning Class #{n}" }
  end
end
