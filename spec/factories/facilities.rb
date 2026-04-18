FactoryBot.define do
  factory :facility do
    name { "CCC" }
    association :city
  end
end
