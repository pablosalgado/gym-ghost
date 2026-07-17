Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "/hello", to: "hello#index"
    end
  end

  root to: redirect("/index.html")
end
