require "rails_helper"

RSpec.describe "BookingRequests", type: :request do
  include_context "with OpenAPI contract"

  describe "POST /api/v1/booking_requests" do
    it "returns unauthorized when header is missing" do
      post "/api/v1/booking_requests", params: { schedule_entry_id: 1 }, as: :json

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
      post "/api/v1/booking_requests",
           params: { schedule_entry_id: 1 },
           headers: { "Authorization" => "Bearer invalid-token" },
           as: :json

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

    it "returns 404 when schedule entry does not exist" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      post "/api/v1/booking_requests",
           params: { schedule_entry_id: 999 },
           headers: { "Authorization" => "Bearer #{raw_token}" },
           as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "status" => 404,
            "title" => "Not Found",
            "detail" => "The requested resource does not exist."
          }
        ]
      )
    end

    it "returns 404 when no gym member profile matches the authenticated user" do
      user = create(:user, email: "noprofile@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2026, 8, 1),
        start_time: Time.zone.parse("2026-08-01 07:00:00 UTC")
      )

      post "/api/v1/booking_requests",
           params: { schedule_entry_id: schedule_entry.id },
           headers: { "Authorization" => "Bearer #{raw_token}" },
           as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "status" => 404,
            "title" => "Not Found",
            "detail" => "The requested resource does not exist."
          }
        ]
      )
    end

    it "schedules job for booking window when it opens in the future" do
      user = create(:user, email: "member@example.com")
      gym_member = create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2026, 8, 1),
        start_time: Time.zone.parse("2026-08-01 07:00:00 UTC")
      )

      expected_window = Time.zone.parse("2026-07-31 07:00:00 UTC")

      expect {
        post "/api/v1/booking_requests",
             params: { schedule_entry_id: schedule_entry.id },
             headers: { "Authorization" => "Bearer #{raw_token}" },
             as: :json
      }.to have_enqueued_job(BookingRequestJob).at(expected_window)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["booking_request"]).to include(
        "status" => "pending",
        "schedule_entry_id" => schedule_entry.id
      )
      expect(body["booking_request"]["id"]).to be_present
      expect(body["booking_request"]["booking_window_opens_at"]).to be_present

      booking_request = BookingRequest.find(body["booking_request"]["id"])
      expect(booking_request.gym_member).to eq(gym_member)
      expect(booking_request.status).to eq("pending")
      expect(booking_request.booking_window_opens_at.utc.iso8601).to eq("2026-07-31T07:00:00Z")
    end

    it "enqueues job immediately when booking window is already open" do
      user = create(:user, email: "member@example.com")
      gym_member = create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      # Create a schedule entry starting 1 hour from now — booking window opened 23 hours ago
      schedule_entry = create(
        :schedule_entry,
        date: Date.current,
        start_time: 1.hour.from_now
      )

      expect {
        post "/api/v1/booking_requests",
             params: { schedule_entry_id: schedule_entry.id },
             headers: { "Authorization" => "Bearer #{raw_token}" },
             as: :json
      }.to have_enqueued_job(BookingRequestJob)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["booking_request"]).to include(
        "status" => "pending",
        "schedule_entry_id" => schedule_entry.id
      )
      expect(body["booking_request"]["id"]).to be_present

      booking_request = BookingRequest.find(body["booking_request"]["id"])
      expect(booking_request.gym_member).to eq(gym_member)
      expect(booking_request.status).to eq("pending")
      expect(booking_request.booking_window_opens_at).to be_past
    end

    it "returns 409 when a duplicate pending booking request exists" do
      user = create(:user, email: "member@example.com")
      gym_member = create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2026, 8, 1),
        start_time: Time.zone.parse("2026-08-01 07:00:00 UTC")
      )

      create(
        :booking_request,
        gym_member: gym_member,
        schedule_entry: schedule_entry,
        status: :pending
      )

      post "/api/v1/booking_requests",
           params: { schedule_entry_id: schedule_entry.id },
           headers: { "Authorization" => "Bearer #{raw_token}" },
           as: :json

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "status" => 409,
            "title" => "Conflict",
            "detail" => "A booking request already exists for this schedule entry."
          }
        ]
      )
    end

    it "returns 422 when the schedule entry is in the past" do
      user = create(:user, email: "member@example.com")
      create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2020, 1, 1),
        start_time: Time.zone.parse("2020-01-01 07:00:00 UTC")
      )

      post "/api/v1/booking_requests",
           params: { schedule_entry_id: schedule_entry.id },
           headers: { "Authorization" => "Bearer #{raw_token}" },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "status" => 422,
            "title" => "Validation Failed",
            "detail" => "Schedule entry is in the past."
          }
        ]
      )
    end
  end
end
