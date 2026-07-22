require "rails_helper"

RSpec.describe "Schedule", type: :request do
  include_context "with OpenAPI contract"

  let(:user) { create(:user) }
  let(:raw_token) { SecureRandom.hex(32) }
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }
  let(:city) { create(:city, city_name: "Bogot\u00e1") }
  let(:facility) { create(:facility, city:, display_name: "Chapinero") }
  let(:activity) { create(:activity, name: "Spinning") }
  let!(:entry) do
    create(:schedule_entry,
      activity:,
      facility:,
      date: Date.new(2026, 7, 21),
      start_time: Time.zone.parse("2026-07-21 07:00:00 UTC"))
  end

  before do
    create(:token, user:, digest: Token.digest(raw_token))
  end

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
      get "/api/v1/schedule", headers: { "Authorization" => "InvalidTokenHere" }

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

    it "returns schedule entries when token is valid" do
      get "/api/v1/schedule", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "schedule" => [
          {
            "id" => entry.id,
            "name" => "Spinning",
            "facility_id" => facility.id,
            "city_id" => city.id,
            "starts_at" => "2026-07-21T07:00:00Z",
            "duration_minutes" => 60
          }
        ]
      )
    end

    it "filters by date" do
      get "/api/v1/schedule", params: { date: "2026-07-21" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["schedule"].size).to eq(1)

      get "/api/v1/schedule", params: { date: "2026-07-22" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["schedule"]).to eq([])
    end

    it "filters by facility_id" do
      other_facility = create(:facility, city:, display_name: "Usaqu\u00e9n")
      create(:schedule_entry,
        activity:,
        facility: other_facility,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 08:00:00 UTC"))

      get "/api/v1/schedule", params: { facility_id: facility.id }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["schedule"].size).to eq(1)
      expect(response.parsed_body["schedule"].first["facility_id"]).to eq(facility.id)
    end

    it "returns empty array when no entries match" do
      get "/api/v1/schedule", params: { date: "2099-01-01" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("schedule" => [])
    end
  end
end
