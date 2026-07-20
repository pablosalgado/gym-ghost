FactoryBot.define do
  factory :activity do
    sequence(:name) { |n| "Spinning Class #{n}" }
  end
end
