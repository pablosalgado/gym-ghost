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

    it "runs SyncFacilitiesJob inline when the cities table is empty" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      service = instance_double(Partner::FacilitiesService)

      allow(Partner::FacilitiesService).to receive(:new).and_return(service)
      allow(service).to receive(:sync) do
        create(:city, city_name: "BOGOTÁ, D.C.")
        []
      end

      get "/api/v1/cities", headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(Partner::FacilitiesService).to have_received(:new).once
      expect(service).to have_received(:sync).once
      expect(response.parsed_body["cities"]).to contain_exactly(
        { "id" => kind_of(Integer), "city_name" => "BOGOTÁ, D.C." }
      )
    end

    it "does not run SyncFacilitiesJob when cities already exist" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:city, city_name: "Medellín")
      service = instance_double(Partner::FacilitiesService)
      allow(Partner::FacilitiesService).to receive(:new).and_return(service)
      allow(service).to receive(:sync)

      get "/api/v1/cities", headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(Partner::FacilitiesService).not_to have_received(:new)
      expect(response.parsed_body["cities"]).to contain_exactly(
        { "id" => kind_of(Integer), "city_name" => "Medellín" }
      )
    end
  end
end
