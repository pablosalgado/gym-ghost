FactoryBot.define do
  factory :scrape_log do
    facility
    date { Date.current }
    status { :completed }
  end
end
