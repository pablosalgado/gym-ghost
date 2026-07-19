Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "/auth", to: "auth#create"
      get "/schedule", to: "schedule#index"
      post "/partner/auth", to: "partner_auth#create"
    end
  end

  root to: redirect("/index.html")
end
