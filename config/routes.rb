Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "/auth", to: "auth#create"
      get "/schedule", to: "schedule#index"
      get "/cities", to: "cities#index"
      get "/facilities", to: "facilities#index"
    end
  end

  root to: redirect("/index.html")
end
