require "rails_helper"

RSpec.describe "Activities", type: :request do
  include_context "with OpenAPI contract"

  describe "GET /api/v1/activities" do
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
      get "/api/v1/activities", headers: { "Authorization" => "Bearer invalid-token" }

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
      let(:headers) { { "Authorization" => "Bearer #{raw_token}" } }

      before do
        create(:token, user: user, digest: Token.digest(raw_token))
      end

      it "returns all activities when no facility_id param" do
        yoga = create(:activity, name: "Yoga")
        pilates = create(:activity, name: "Pilates")

        get "/api/v1/activities", headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "activities" => [
            { "id" => pilates.id, "name" => "Pilates" },
            { "id" => yoga.id, "name" => "Yoga" }
          ]
        )
      end

      it "returns activities filtered by facility_id" do
        yoga = create(:activity, name: "Yoga")
        pilates = create(:activity, name: "Pilates")
        spinning = create(:activity, name: "Spinning")

        facility = create(:facility)

        create(:schedule_entry, activity: yoga, facility: facility)
        create(:schedule_entry, activity: pilates, facility: facility)

        get "/api/v1/activities", headers: headers, params: { facility_id: facility.id }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "activities" => [
            { "id" => pilates.id, "name" => "Pilates" },
            { "id" => yoga.id, "name" => "Yoga" }
          ]
        )
      end

      it "returns empty array when facility has no schedule entries" do
        create(:activity, name: "Yoga")
        facility = create(:facility)

        get "/api/v1/activities", headers: headers, params: { facility_id: facility.id }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq("activities" => [])
      end

      context "with OpenAPI contract" do
        it "conforms to the OpenAPI schema for a successful response" do
          create(:activity, name: "Yoga")

          get "/api/v1/activities", headers: headers

          expect(response).to have_http_status(:ok)
        end

        it "conforms to the OpenAPI schema for a filtered response" do
          yoga = create(:activity, name: "Yoga")
          facility = create(:facility)
          create(:schedule_entry, activity: yoga, facility: facility)

          get "/api/v1/activities", headers: headers, params: { facility_id: facility.id }

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
