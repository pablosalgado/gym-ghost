require "rails_helper"

RSpec.describe "Schedule", type: :request do
  describe "GET /api/v1/schedule" do
    it "returns unauthorized when header is missing" do
      get "/api/v1/schedule"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "status" => 401,
            "title" => "Unauthorized",
            "detail" => "Authentication token is missing or invalid."
          }
        ]
      )
    end

    it "returns unauthorized when token is invalid" do
      get "/api/v1/schedule", headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "status" => 401,
            "title" => "Unauthorized",
            "detail" => "Authentication token is missing or invalid."
          }
        ]
      )
    end

    it "returns schedule when token is valid" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule", headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body).to have_key("schedule")
      expect(body["schedule"]).to be_an(Array)
      expect(body["schedule"].size).to be_positive
    end

    it "returns schedule entries with required fields" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule", headers: { "Authorization" => "Bearer #{raw_token}" }

      entry = response.parsed_body["schedule"].first

      expect(entry).to include(
        "id" => a_string_matching(/\A.+\z/),
        "name" => a_string_matching(/\A.+\z/),
        "start_time" => a_string_matching(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/),
        "facility" => a_string_matching(/\A.+\z/),
        "city" => a_string_matching(/\A.+\z/)
      )
    end

    it "returns schedule spanning 14 days" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule", headers: { "Authorization" => "Bearer #{raw_token}" }

      dates = response.parsed_body["schedule"].map { |e| Date.parse(e["start_time"]) }.uniq.sort

      expect(dates.size).to eq(14)
      expect(dates.last - dates.first).to eq(13)
    end

    it "includes classes from both Bogota and Medellin" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule", headers: { "Authorization" => "Bearer #{raw_token}" }

      cities = response.parsed_body["schedule"].map { |e| e["city"] }.uniq

      expect(cities).to include("Bogota", "Medellin")
    end
  end
end
