FactoryBot.define do
  factory :token do
    association :user

    transient do
      raw_token { SecureRandom.hex(32) }
    end

    digest { Token.digest(raw_token) }
  end
end
