require "rails_helper"

RSpec.describe "Schedule", type: :request do
  include_context "with OpenAPI contract"
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

    describe "with valid authentication" do
      let(:user) { create(:user) }
      let(:raw_token) { SecureRandom.hex(32) }
      let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

      before do
        create(:token, user:, digest: Token.digest(raw_token))
      end

      it "returns schedule for a given date" do
        activity = create(:activity, name: "Yoga")
        facility = create(:facility)
        schedule_entry = create(:schedule_entry,
          activity:,
          facility:,
          date: "2026-07-25",
          start_time: Time.zone.parse("2026-07-25T14:00:00"))

        get "/api/v1/schedule", params: { date: "2026-07-25" }, headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "schedule" => [
            {
              "id" => schedule_entry.id,
              "activity_name" => "Yoga",
              "activity_id" => activity.id,
              "facility_id" => facility.id,
              "starts_at" => "2026-07-25T14:00:00.000Z"
            }
          ]
        )
      end

      it "returns schedule for a given date and facility" do
        yoga = create(:activity, name: "Yoga")
        pilates = create(:activity, name: "Pilates")
        facility_1 = create(:facility)
        facility_2 = create(:facility)

        create(:schedule_entry,
          activity: yoga,
          facility: facility_1,
          date: "2026-07-25",
          start_time: Time.zone.parse("2026-07-25T14:00:00"))
        create(:schedule_entry,
          activity: pilates,
          facility: facility_2,
          date: "2026-07-25",
          start_time: Time.zone.parse("2026-07-25T15:00:00"))

        get "/api/v1/schedule", params: { date: "2026-07-25", facility_id: facility_1.id },
          headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["schedule"].size).to eq(1)
        expect(response.parsed_body["schedule"].first["activity_name"]).to eq("Yoga")
        expect(response.parsed_body["schedule"].first["facility_id"]).to eq(facility_1.id)
      end

      it "defaults date to today when omitted" do
        today_str = Time.zone.today.to_s
        activity = create(:activity, name: "Zumba")
        facility = create(:facility)
        schedule_entry = create(:schedule_entry,
          activity:,
          facility:,
          date: today_str,
          start_time: Time.zone.parse("#{today_str}T10:00:00"))

        get "/api/v1/schedule", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["schedule"].size).to eq(1)
        expect(response.parsed_body["schedule"].first["id"]).to eq(schedule_entry.id)
      end

      it "returns empty array when no entries match" do
        get "/api/v1/schedule", params: { date: "2099-01-01" }, headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq("schedule" => [])
      end
    end
  end
end
