FactoryBot.define do
  factory :booking_request do
    gym_member
    schedule_entry
    status { :pending }
    booking_window_opens_at { 1.day.from_now }

    trait :booked do
      status { :booked }
      partner_confirmation_id { "conf-abc123" }
    end

    trait :failed do
      status { :failed }
      error_message { "Booking window closed" }
    end
  end
end
