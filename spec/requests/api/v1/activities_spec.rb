require "rails_helper"

RSpec.describe "Activities", type: :request do
  include_context "with OpenAPI contract"

  describe "GET /api/v1/activities" do
    def auth_headers
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      { "Authorization" => "Bearer #{raw_token}" }
    end

    it "returns unauthorized when header is missing" do
      get "/api/v1/activities"

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
      get "/api/v1/activities", headers: { "Authorization" => "Bearer invalidtoken" }

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

    it "returns all activities when no facility_id param" do
      create(:activity, name: "Yoga")
      create(:activity, name: "Spinning")

      get "/api/v1/activities", headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("activities")
      expect(body["activities"].size).to eq(2)
    end

    it "returns only safe fields (id and name)" do
      create(:activity, name: "Yoga")

      get "/api/v1/activities", headers: auth_headers

      activity = response.parsed_body["activities"].first
      expect(activity.keys).to match_array(%w[id name])
    end

    it "returns activities filtered by facility_id" do
      yoga = create(:activity, name: "Yoga")
      spinning = create(:activity, name: "Spinning")
      facility = create(:facility)
      create(:schedule_entry, activity: yoga, facility: facility)

      get "/api/v1/activities?facility_id=#{facility.id}", headers: auth_headers

      activities = response.parsed_body["activities"]
      expect(activities.size).to eq(1)
      expect(activities.first["name"]).to eq("Yoga")
    end

    it "returns empty array when facility has no schedule entries" do
      create(:activity, name: "Yoga")
      facility = create(:facility)

      get "/api/v1/activities?facility_id=#{facility.id}", headers: auth_headers

      expect(response.parsed_body["activities"]).to eq([])
    end

    it "returns empty array when facility_id does not exist" do
      get "/api/v1/activities?facility_id=99999", headers: auth_headers

      expect(response.parsed_body["activities"]).to eq([])
    end
  end
end
