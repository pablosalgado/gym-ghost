FactoryBot.define do
  factory :city do
    sequence(:city_name) { |n| "City #{n}" }
  end
end
