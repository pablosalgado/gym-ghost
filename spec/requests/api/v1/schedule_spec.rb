require "rails_helper"

RSpec.describe "Schedule", type: :request do
  include_context "with OpenAPI contract"

  describe "GET /api/v1/schedule" do
    let(:frozen_time) { Time.zone.parse("2026-07-21T06:00:00Z") }

    around do |example|
      travel_to(frozen_time) { example.run }
    end
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

      get "/api/v1/schedule",
          params: { date: "2026-07-21", facility_id: facility_a.id },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["schedule"].length).to eq(1)
      expect(body["schedule"].first["facility_id"]).to eq(facility_a.id)
    end

    it "calls Partner::ActivitiesService#fetch on cache miss with facility_id and returns results" do
      facility = create(:facility)
      service = instance_double(Partner::ActivitiesService, fetch: [])
      allow(Partner::ActivitiesService).to receive(:new).and_return(service)

      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-07-22", facility_id: facility.id },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(Partner::ActivitiesService).to have_received(:new).once
      expect(service).to have_received(:fetch).with(facility: facility, date: "2026-07-22").once

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
    end

    it "does not call Partner::ActivitiesService when facility_id is missing on cache miss" do
      allow(Partner::ActivitiesService).to receive(:new)

      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-07-22" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(Partner::ActivitiesService).not_to have_received(:new)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
    end

    it "returns empty schedule when facility_id does not exist (nil guard in service)" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-07-22", facility_id: 999999 },
          headers: { "Authorization" => "Bearer #{raw_token}" }

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

    it "includes null booking_request when no gym member profile exists" do
      facility = create(:facility)
      class_type = create(:class_type, name: "Yoga")
      create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 07:00:00 UTC")
      )

      user = create(:user, email: "no-gym-profile@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-07-21" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["schedule"].length).to eq(1)
      expect(body["schedule"].first["booking_request"]).to be_nil
    end

    it "includes pending booking_request for sessions with a pending request" do
      facility = create(:facility)
      class_type = create(:class_type, name: "Spinning")
      schedule_entry = create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 8, 1),
        start_time: Time.zone.parse("2026-08-01 07:00:00 UTC")
      )

      user = create(:user, email: "member@example.com")
      gym_member = create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      booking_request = create(
        :booking_request,
        gym_member: gym_member,
        schedule_entry: schedule_entry,
        status: :pending,
        booking_window_opens_at: Time.zone.parse("2026-07-31 07:00:00 UTC")
      )

      get "/api/v1/schedule",
          params: { date: "2026-08-01" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["schedule"].length).to eq(1)
      expect(body["schedule"].first["booking_request"]).to eq(
        "id" => booking_request.id,
        "status" => "pending",
        "booking_window_opens_at" => "2026-07-31T07:00:00Z"
      )
    end

    it "includes booked booking_request for sessions with a booked request" do
      facility = create(:facility)
      class_type = create(:class_type, name: "CrossFit")
      schedule_entry = create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 8, 2),
        start_time: Time.zone.parse("2026-08-02 09:00:00 UTC")
      )

      user = create(:user, email: "member@example.com")
      gym_member = create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      booking_request = create(
        :booking_request,
        :booked,
        gym_member: gym_member,
        schedule_entry: schedule_entry,
        booking_window_opens_at: Time.zone.parse("2026-08-01 09:00:00 UTC")
      )

      get "/api/v1/schedule",
          params: { date: "2026-08-02" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["schedule"].length).to eq(1)
      expect(body["schedule"].first["booking_request"]).to eq(
        "id" => booking_request.id,
        "status" => "booked",
        "booking_window_opens_at" => "2026-08-01T09:00:00Z"
      )
    end

    it "includes null booking_request for session with no request when gym member exists" do
      facility = create(:facility)
      class_type = create(:class_type, name: "Yoga")
      create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 8, 3),
        start_time: Time.zone.parse("2026-08-03 07:00:00 UTC")
      )

      user = create(:user, email: "member@example.com")
      create(:gym_member, email: "member@example.com")
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-08-03" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["schedule"].length).to eq(1)
      expect(body["schedule"].first["booking_request"]).to be_nil
    end

    it "excludes entries with start_time in the past when same day has future entries" do
      facility = create(:facility)
      class_type = create(:class_type, name: "Yoga")
      future_entry = create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 07:00:00 UTC")
      )
      create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 05:00:00 UTC")
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
      expect(body["schedule"].first["id"]).to eq(future_entry.id)
    end

    it "returns empty schedule when all entries for the date are in the past" do
      facility = create(:facility)
      class_type = create(:class_type, name: "Yoga")
      create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 04:00:00 UTC")
      )
      create(
        :schedule_entry,
        facility: facility,
        class_type: class_type,
        date: Date.new(2026, 7, 21),
        start_time: Time.zone.parse("2026-07-21 05:00:00 UTC")
      )

      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/schedule",
          params: { date: "2026-07-21" },
          headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
    end

    it "returns all entries when all start_times are in the future" do
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
      expect(body["schedule"].length).to eq(2)
    end
  end
end
