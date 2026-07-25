Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "/auth", to: "auth#create"
      get "/schedule", to: "schedule#index"
      get "/cities", to: "cities#index"
      get "/facilities", to: "facilities#index"
      resources :booking_requests, only: [ :create ]
      get "/openapi.json", to: "openapi#show"
      get "/docs", to: "docs#show"
    end
  end

  root to: redirect("/index.html")

  # Serve index.html for client-side routes (SPA fallback).
  # Non-API/non-health-check HTML GET requests get the React app entry point
  # so React Router can handle /login, /schedule, etc.
  get "*path",
    to: ->(_) { [ 200, { Rack::CONTENT_TYPE => "text/html; charset=utf-8" }, [ Rails.public_path.join("index.html").read ] ] },
    constraints: ->(req) { !req.path.start_with?("/api/", "/up") }
end
