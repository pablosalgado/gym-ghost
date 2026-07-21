require "rails_helper"

RSpec.describe "Facilities", type: :request do
  include_context "with OpenAPI contract"
  describe "GET /api/v1/facilities" do
    it "returns unauthorized when header is missing" do
      get "/api/v1/facilities"

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
      get "/api/v1/facilities", headers: { "Authorization" => "Bearer invalid-token" }

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

    it "returns all facilities when no city_id param" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      city = create(:city)
      create(:facility, display_name: "Alpha", city: city)
      create(:facility, display_name: "Beta", city: city)

      get "/api/v1/facilities", headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("facilities")
      expect(body["facilities"].size).to eq(2)
    end

    it "returns facilities filtered by city_id" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      city_a = create(:city)
      city_b = create(:city)
      facility_in_a = create(:facility, display_name: "Alpha", city: city_a)
      create(:facility, display_name: "Beta", city: city_b)

      get "/api/v1/facilities?city_id=#{city_a.id}",
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      facilities = response.parsed_body["facilities"]
      expect(facilities.size).to eq(1)
      expect(facilities.first["id"]).to eq(facility_in_a.id)
    end

    it "returns only safe fields (no evo_token, no external_id)" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:facility, city: create(:city))

      get "/api/v1/facilities", headers: { "Authorization" => "Bearer #{raw_token}" }

      facility = response.parsed_body["facilities"].first
      expect(facility.keys).to match_array(%w[id display_name city_id])
    end

    it "returns empty array when city_id has no facilities" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      city = create(:city)

      get "/api/v1/facilities?city_id=#{city.id}",
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["facilities"]).to eq([])
    end
  end
end
