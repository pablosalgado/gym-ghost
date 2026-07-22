require "rails_helper"

RSpec.describe "Cities", type: :request do
  include_context "with OpenAPI contract"
  describe "GET /api/v1/cities" do
    it "returns unauthorized when header is missing" do
      get "/api/v1/cities"

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
      get "/api/v1/cities", headers: { "Authorization" => "Bearer invalid-token" }

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

    it "returns cities when token is valid" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:city, city_name: "BOGOTÁ, D.C.")

      get "/api/v1/cities", headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("cities")
      expect(body["cities"]).to be_an(Array)
      expect(body["cities"]).to contain_exactly(
        { "id" => kind_of(Integer), "city_name" => "BOGOTÁ, D.C." }
      )
    end

    it "returns only safe fields on cities" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:city, city_name: "Medellín")

      get "/api/v1/cities", headers: { "Authorization" => "Bearer #{raw_token}" }

      city = response.parsed_body["cities"].first
      expect(city.keys).to match_array(%w[id city_name])
    end

    it "enqueues SyncFacilitiesJob when the cities table is empty" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      expect { get "/api/v1/cities", headers: { "Authorization" => "Bearer #{raw_token}" } }
        .to have_enqueued_job(SyncFacilitiesJob)
    end

    it "does not enqueue SyncFacilitiesJob when cities already exist" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:city)

      expect { get "/api/v1/cities", headers: { "Authorization" => "Bearer #{raw_token}" } }
        .not_to have_enqueued_job(SyncFacilitiesJob)
    end
  end
end
