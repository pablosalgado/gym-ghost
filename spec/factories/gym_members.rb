FactoryBot.define do
  factory :gym_member do
    sequence(:email) { |n| "member#{n}@example.com" }
    password { "Password123!" }
    password_confirmation { password }
  end
end
