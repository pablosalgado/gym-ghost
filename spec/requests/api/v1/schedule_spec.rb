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

    it "returns empty schedule and class_types when no entries exist" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule", headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
    end

    it "returns schedule entries filtered by date" do
      facility = create(:facility)
      class_type = create(:class_type, name: "Yoga")
      schedule_entry = create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 07:00:00 UTC")
      )

      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-07-21" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["schedule"].length).to eq(1)
      expect(body["schedule"].first).to include(
        "id" => schedule_entry.id,
        "activity_name" => "Yoga",
        "activity_id" => class_type.id,
        "facility_id" => facility.id,
        "starts_at" => "2026-07-21T07:00:00Z"
      )
      expect(body["class_types"]).to eq([ { "id" => class_type.id, "name" => "Yoga" } ])
    end

    it "returns schedule entries filtered by date and facility_id" do
      facility_a = create(:facility, display_name: "Gym A")
      facility_b = create(:facility, display_name: "Gym B")
      class_type = create(:class_type, name: "CrossFit")
      create(
        :schedule_entry,
        facility: facility_a,
        class_type: class_type,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 09:00:00 UTC")
      )
      create(
        :schedule_entry,
        facility: facility_b,
        class_type: class_type,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 10:00:00 UTC")
      )

      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      expect {
        get "/api/v1/schedule",
            params: { date: "2026-07-21", facility_id: facility_a.id },
            headers: { "Authorization" => "Bearer #{raw_token}" }
      }.not_to have_enqueued_job(FetchScheduleEntriesJob)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["schedule"].length).to eq(1)
      expect(body["schedule"].first["facility_id"]).to eq(facility_a.id)
    end

    it "enqueues FetchScheduleEntriesJob on cache miss with facility_id and returns empty results" do
      facility = create(:facility)

      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      expect {
        get "/api/v1/schedule",
            params: { date: "2026-07-22", facility_id: facility.id },
            headers: { "Authorization" => "Bearer #{raw_token}" }
      }.to have_enqueued_job(FetchScheduleEntriesJob)
        .with(facility.id.to_s, "2026-07-22")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
    end

    it "does not enqueue job when facility_id is missing on cache miss" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      expect {
        get "/api/v1/schedule",
            params: { date: "2026-07-22" },
            headers: { "Authorization" => "Bearer #{raw_token}" }
      }.not_to have_enqueued_job(FetchScheduleEntriesJob)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
    end

    it "returns class_types with unique entries from the schedule results" do
      facility = create(:facility)
      yoga = create(:class_type, name: "Yoga")
      spinning = create(:class_type, name: "Spinning")
      create(
        :schedule_entry,
        facility: facility,
        class_type: yoga,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 07:00:00 UTC")
      )
      create(
        :schedule_entry,
        facility: facility,
        class_type: spinning,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 08:00:00 UTC")
      )

      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-07-21" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["class_types"]).to contain_exactly(
        { "id" => yoga.id, "name" => "Yoga" },
        { "id" => spinning.id, "name" => "Spinning" }
      )
    end

    it "returns empty results for a date with no entries" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-07-22" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
    end
  end
end
