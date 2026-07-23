require "rails_helper"

RSpec.describe "OpenAPI", type: :request do
  describe "GET /api/v1/openapi.json" do
    it "returns the OpenAPI spec as JSON" do
      get "/api/v1/openapi.json"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to be_a(Hash)
      expect(body).to include("openapi", "info", "paths")
      expect(body["openapi"]).to eq("3.0.3")
      expect(body.dig("info", "title")).to eq("Gym Ghost API")
    end

    it "does not require authentication" do
      get "/api/v1/openapi.json"
      expect(response).to have_http_status(:ok)
    end

    it "includes all API endpoints in paths" do
      get "/api/v1/openapi.json"
      paths = response.parsed_body["paths"]
      expect(paths).to have_key("/api/v1/auth")
      expect(paths).to have_key("/api/v1/schedule")
      expect(paths).to have_key("/api/v1/cities")
      expect(paths).to have_key("/api/v1/facilities")
    end
  end

  describe "GET /api/v1/docs" do
    it "returns Swagger UI HTML" do
      get "/api/v1/docs"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/html")
      expect(response.body).to include("swagger-ui")
      expect(response.body).to include("/api/v1/openapi.json")
    end

    it "does not require authentication" do
      get "/api/v1/docs"
      expect(response).to have_http_status(:ok)
    end
  end
end
