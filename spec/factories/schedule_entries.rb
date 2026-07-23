FactoryBot.define do
  factory :schedule_entry do
    class_type
    facility
    date { Date.new(2026, 7, 21) }
    start_time { Time.zone.parse("2026-07-21 07:00:00 UTC") }
  end
end
