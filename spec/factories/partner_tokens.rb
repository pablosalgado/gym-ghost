FactoryBot.define do
  factory :partner_token do
    association :gym_member

    access_token { SecureRandom.hex(32) }
    refresh_token { SecureRandom.hex(32) }
    token_expires_at { 1.hour.from_now }
  end
end
