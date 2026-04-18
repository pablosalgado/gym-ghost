FactoryBot.define do
  factory :schedule do
    association :facility
    association :class_type
    day_of_week { :monday }
    start_time { Time.zone.parse("10:00") }
    is_holiday_schedule { false }
  end
end
