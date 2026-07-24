FactoryBot.define do
  factory :schedule_entry do
    class_type
    facility
    date { Date.new(2026, 7, 21) }
    start_time { Time.zone.parse("2026-07-21 07:00:00 UTC") }
    partner_activity_id { "550e8400-e29b-41d4-a716-446655440000" }
    activ_config_id { 42 }
  end
end
