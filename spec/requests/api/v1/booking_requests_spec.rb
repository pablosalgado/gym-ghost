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

    it "returns 204 when no gym members exist" do
      user = create(:user, email: "noprofile@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2026, 8, 1),
        start_time: Time.parse("2026-08-01 07:00:00 UTC")
      )

      expect {
        post "/api/v1/booking_requests",
             params: { schedule_entry_id: schedule_entry.id },
             headers: { "Authorization" => "Bearer #{raw_token}" },
             as: :json
      }.to change(BookingRequest, :count).by(0)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it "creates booking requests for all gym members" do
      user = create(:user, email: "member@example.com")
      gym_member_1 = create(:gym_member, email: "member1@example.com")
      gym_member_2 = create(:gym_member, email: "member2@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2026, 8, 1),
        start_time: Time.parse("2026-08-01 07:00:00 UTC")
      )

      expected_window = Time.parse("2026-07-31 07:00:00 UTC")

      expect {
        post "/api/v1/booking_requests",
             params: { schedule_entry_id: schedule_entry.id },
             headers: { "Authorization" => "Bearer #{raw_token}" },
             as: :json
      }.to have_enqueued_job(BookingRequestJob).twice

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["booking_request"]).to include(
        "status" => "pending",
        "schedule_entry_id" => schedule_entry.id
      )
      expect(body["booking_request"]["id"]).to be_present
      expect(body["booking_request"]["booking_window_opens_at"]).to be_present
      expect(body["created_count"]).to eq(2)

      expect(BookingRequest.count).to eq(2)
      booking_requests = BookingRequest.where(schedule_entry: schedule_entry)
      expect(booking_requests.pluck(:gym_member_id)).to contain_exactly(
        gym_member_1.id, gym_member_2.id
      )
    end

    it "schedules job for booking window when it opens in the future" do
      travel_to(Time.parse("2026-07-21T06:00:00Z")) do
        user = create(:user, email: "member@example.com")
        gym_member = create(:gym_member, email: "member@example.com")
        raw_token = SecureRandom.hex(32)
        create(:token, user:, digest: Token.digest(raw_token))

        schedule_entry = create(
          :schedule_entry,
          date: Date.new(2026, 8, 1),
          start_time: Time.parse("2026-08-01 07:00:00 UTC")
        )

        expected_window = Time.parse("2026-07-31 07:00:00 UTC")

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
        expect(body["created_count"]).to eq(1)

        booking_request = BookingRequest.find(body["booking_request"]["id"])
        expect(booking_request.gym_member).to eq(gym_member)
        expect(booking_request.status).to eq("pending")
        expect(booking_request.booking_window_opens_at.utc.iso8601).to eq("2026-07-31T07:00:00Z")
      end
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
      expect(body["created_count"]).to eq(1)

      booking_request = BookingRequest.find(body["booking_request"]["id"])
      expect(booking_request.gym_member).to eq(gym_member)
      expect(booking_request.status).to eq("pending")
      expect(booking_request.booking_window_opens_at).to be_past
    end

    it "returns 204 when all members already have pending booking requests" do
      user = create(:user, email: "member@example.com")
      gym_member = create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2026, 8, 1),
        start_time: Time.parse("2026-08-01 07:00:00 UTC")
      )

      create(
        :booking_request,
        gym_member: gym_member,
        schedule_entry: schedule_entry,
        status: :pending
      )

      expect {
        post "/api/v1/booking_requests",
             params: { schedule_entry_id: schedule_entry.id },
             headers: { "Authorization" => "Bearer #{raw_token}" },
             as: :json
      }.to have_enqueued_job(BookingRequestJob).exactly(0)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it "returns 201 with correct count when some members are duplicates" do
      user = create(:user, email: "member@example.com")
      gym_member_1 = create(:gym_member, email: "member1@example.com")
      gym_member_2 = create(:gym_member, email: "member2@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2026, 8, 1),
        start_time: Time.parse("2026-08-01 07:00:00 UTC")
      )

      create(
        :booking_request,
        gym_member: gym_member_1,
        schedule_entry: schedule_entry,
        status: :pending
      )

      expect {
        post "/api/v1/booking_requests",
             params: { schedule_entry_id: schedule_entry.id },
             headers: { "Authorization" => "Bearer #{raw_token}" },
             as: :json
      }.to have_enqueued_job(BookingRequestJob).once

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["booking_request"]).to include(
        "status" => "pending",
        "schedule_entry_id" => schedule_entry.id
      )
      expect(body["created_count"]).to eq(1)

      new_booking_requests = BookingRequest.where(
        schedule_entry: schedule_entry,
        gym_member: gym_member_2
      )
      expect(new_booking_requests.count).to eq(1)
    end

    it "returns 422 when the schedule entry is in the past" do
      user = create(:user, email: "member@example.com")
      create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      schedule_entry = create(
        :schedule_entry,
        date: Date.new(2020, 1, 1),
        start_time: Time.parse("2020-01-01 07:00:00 UTC")
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

  describe "DELETE /api/v1/booking_requests/:id" do
    it "returns 401 when no token is provided" do
      booking_request = create(:booking_request)
      delete "/api/v1/booking_requests/#{booking_request.id}"

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

    it "returns 401 when token is invalid" do
      booking_request = create(:booking_request)
      delete "/api/v1/booking_requests/#{booking_request.id}",
             headers: { "Authorization" => "Bearer invalid-token" }

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

    it "returns 204 and destroys the booking request" do
      user = create(:user, email: "member@example.com")
      gym_member = create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      booking_request = create(:booking_request, gym_member:)

      expect {
        delete "/api/v1/booking_requests/#{booking_request.id}",
               headers: { "Authorization" => "Bearer #{raw_token}" }
      }.to change(BookingRequest, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it "returns 404 when booking request does not exist" do
      user = create(:user, email: "member@example.com")
      create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      delete "/api/v1/booking_requests/99999",
             headers: { "Authorization" => "Bearer #{raw_token}" }

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

    it "allows any authenticated user to cancel a booking request by ID" do
      owner = create(:user, email: "owner@example.com")
      owner_member = create(:gym_member, email: "owner@example.com")

      booking_request = create(:booking_request, gym_member: owner_member)

      other_user = create(:user, email: "other@example.com")
      create(:gym_member, email: "other@example.com")
      other_raw_token = SecureRandom.hex(32)
      create(:token, user: other_user, digest: Token.digest(other_raw_token))

      expect {
        delete "/api/v1/booking_requests/#{booking_request.id}",
               headers: { "Authorization" => "Bearer #{other_raw_token}" }
      }.to change(BookingRequest, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "allows any authenticated user to cancel a booking request regardless of gym member profile" do
      user = create(:user, email: "noprofile@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      booking_request = create(:booking_request)

      expect {
        delete "/api/v1/booking_requests/#{booking_request.id}",
               headers: { "Authorization" => "Bearer #{raw_token}" }
      }.to change(BookingRequest, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "allows cancelling a booking request in failed status" do
      user = create(:user, email: "member@example.com")
      gym_member = create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      booking_request = create(:booking_request, :failed, gym_member:)

      expect {
        delete "/api/v1/booking_requests/#{booking_request.id}",
               headers: { "Authorization" => "Bearer #{raw_token}" }
      }.to change(BookingRequest, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
