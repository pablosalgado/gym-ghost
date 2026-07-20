FactoryBot.define do
  factory :facility do
    sequence(:external_id) { |n| n + 100 }
    name { "Branch Gym" }
    evo_token { "evo-token-abc" }
    display_name { "Branch Display" }
    city
  end
end
