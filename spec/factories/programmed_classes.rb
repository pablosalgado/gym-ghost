FactoryBot.define do
  factory :programmed_class do
    association :schedule
    association :user
    status { "programmed" }
  end
end
