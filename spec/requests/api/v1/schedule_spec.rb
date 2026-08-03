require "rails_helper"

RSpec.describe "Schedule", type: :request do
  include_context "with OpenAPI contract"

  def get_without_contract_validation(path, **options)
    previous_app = @_committee_app
    @_committee_app = Rails.application
    get(path, **options)
  ensure
    @_committee_app = previous_app
  end

  describe "GET /api/v1/schedule" do
    let(:frozen_time) { Time.zone.parse("2026-07-21T06:00:00Z") }

    around do |example|
      travel_to(frozen_time) { example.run }
    end

    context "when authentication is missing or invalid" do
      it "returns unauthorized when header is missing" do
        get "/api/v1/schedule", params: { city_id: 1, facility_id: 1, date: "2026-07-21" }

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
        get "/api/v1/schedule",
            params: { city_id: 1, facility_id: 1, date: "2026-07-21" },
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
    end

    context "when authenticated" do
      let(:user) { create(:user) }
      let(:raw_token) { SecureRandom.hex(32) }
      let(:headers) { { "Authorization" => "Bearer #{raw_token}" } }
      let(:facility) { create(:facility) }
      let(:city) { facility.city }
      let(:scope_params) { { city_id: city.id, facility_id: facility.id } }

      before do
        create(:token, user:, raw_token:)
      end

      context "when a required parameter is missing" do
        it "requires city_id, facility_id, and date" do
          get_without_contract_validation "/api/v1/schedule", headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body).to eq(
            "errors" => [
              {
                "status" => 422,
                "title" => "Validation Failed",
                "detail" => "city_id and facility_id and date are required."
              }
            ]
          )
        end

        it "requires city_id" do
          get_without_contract_validation(
            "/api/v1/schedule",
            params: { facility_id: facility.id, date: "2026-07-21" },
            headers: headers
          )

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.dig("errors", 0, "detail")).to eq("city_id is required.")
        end

        it "requires facility_id" do
          get_without_contract_validation(
            "/api/v1/schedule",
            params: { city_id: city.id, date: "2026-07-21" },
            headers: headers
          )

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.dig("errors", 0, "detail")).to eq("facility_id is required.")
        end

        it "requires date" do
          expect(Partner::ActivitiesService).not_to receive(:new)

          get_without_contract_validation "/api/v1/schedule", params: scope_params, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.dig("errors", 0, "detail")).to eq("date is required.")
        end
      end

      context "when the requested scope is invalid" do
        it "rejects a city that does not exist" do
          expect(Partner::ActivitiesService).not_to receive(:new)

          get "/api/v1/schedule",
              params: scope_params.merge(city_id: 999_999, date: "2026-07-22"),
              headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.dig("errors", 0, "detail")).to eq("City not found.")
        end

        it "rejects a facility that does not exist" do
          expect(Partner::ActivitiesService).not_to receive(:new)

          get "/api/v1/schedule",
              params: scope_params.merge(facility_id: 999_999, date: "2026-07-22"),
              headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.dig("errors", 0, "detail")).to eq("Facility not found.")
        end

        it "rejects a facility from a different city" do
          other_facility = create(:facility)
          expect(Partner::ActivitiesService).not_to receive(:new)

          get "/api/v1/schedule",
              params: scope_params.merge(facility_id: other_facility.id, date: "2026-07-22"),
              headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.dig("errors", 0, "detail")).to eq(
            "Facility does not belong to the requested city."
          )
        end
      end

      context "when the service has no entries for the facility and date" do
        it "delegates to Partner::ActivitiesService#fetch and renders the empty result" do
          service = instance_double(Partner::ActivitiesService, fetch: [])
          allow(Partner::ActivitiesService).to receive(:new).and_return(service)

          get "/api/v1/schedule",
              params: scope_params.merge(date: "2026-07-22"),
              headers: headers

          expect(Partner::ActivitiesService).to have_received(:new).once
          expect(service).to have_received(:fetch).with(facility: facility, date: "2026-07-22").once

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
        end
      end

      context "when the facility and date have local entries" do
        let(:class_type) { create(:class_type, name: "Yoga") }
        let(:schedule_entry) do
          create(
            :schedule_entry,
            facility: facility,
            class_type: class_type,
            date: Date.new(2026, 7, 21),
            start_time: Time.zone.parse("2026-07-21 07:00:00 UTC")
          )
        end

        it "returns the full payload for the requested facility and date" do
          schedule_entry

          get "/api/v1/schedule", params: scope_params.merge(date: "2026-07-21"), headers: headers

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

        it "filters entries to the requested facility" do
          other_facility = create(:facility, display_name: "Gym B")
          create(
            :schedule_entry,
            facility: other_facility,
            class_type: class_type,
            date: Date.new(2026, 7, 21),
            start_time: Time.zone.parse("2026-07-21 09:00:00 UTC")
          )
          schedule_entry

          get "/api/v1/schedule", params: scope_params.merge(date: "2026-07-21"), headers: headers

          expect(response).to have_http_status(:ok)
          body = response.parsed_body
          expect(body["schedule"].length).to eq(1)
          expect(body["schedule"].first["facility_id"]).to eq(facility.id)
        end

        it "filters cache-miss results to the requested facility" do
          other_facility = create(:facility, display_name: "Gym B")
          other_entry = create(
            :schedule_entry,
            facility: other_facility,
            class_type: class_type,
            date: Date.new(2026, 7, 21),
            start_time: Time.zone.parse("2026-07-21 09:00:00 UTC")
          )
          schedule_entry
          service = instance_double(Partner::ActivitiesService, fetch: [ other_entry, schedule_entry ])
          allow(Partner::ActivitiesService).to receive(:new).and_return(service)

          get "/api/v1/schedule", params: scope_params.merge(date: "2026-07-21"), headers: headers

          expect(response).to have_http_status(:ok)
          body = response.parsed_body
          expect(body["schedule"].map { |entry| entry["facility_id"] }).to eq([ facility.id ])
        end

        it "returns unique class types across the schedule entries" do
          spinning = create(:class_type, name: "Spinning")
          create(
            :schedule_entry,
            facility: facility,
            class_type: spinning,
            date: Date.new(2026, 7, 21),
            start_time: Time.zone.parse("2026-07-21 08:00:00 UTC")
          )
          schedule_entry

          get "/api/v1/schedule", params: scope_params.merge(date: "2026-07-21"), headers: headers

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["class_types"]).to contain_exactly(
            { "id" => class_type.id, "name" => "Yoga" },
            { "id" => spinning.id, "name" => "Spinning" }
          )
        end

        it "excludes entries whose start_time is in the past" do
          create(
            :schedule_entry,
            facility: facility,
            class_type: class_type,
            date: Date.new(2026, 7, 21),
            start_time: Time.zone.parse("2026-07-21 05:00:00 UTC")
          )
          schedule_entry

          get "/api/v1/schedule", params: scope_params.merge(date: "2026-07-21"), headers: headers

          expect(response).to have_http_status(:ok)
          body = response.parsed_body
          expect(body["schedule"].length).to eq(1)
          expect(body["schedule"].first["id"]).to eq(schedule_entry.id)
        end

        it "returns all entries when all start_times are in the future" do
          spinning = create(:class_type, name: "Spinning")
          create(
            :schedule_entry,
            facility: facility,
            class_type: spinning,
            date: Date.new(2026, 7, 21),
            start_time: Time.zone.parse("2026-07-21 08:00:00 UTC")
          )
          schedule_entry

          get "/api/v1/schedule", params: scope_params.merge(date: "2026-07-21"), headers: headers

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["schedule"].length).to eq(2)
        end

        it "returns an empty schedule when all entries for the date are in the past" do
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

          get "/api/v1/schedule", params: scope_params.merge(date: "2026-07-21"), headers: headers

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq("schedule" => [], "class_types" => [])
        end

        it "includes null booking_request when no gym member profile exists" do
          schedule_entry

          get "/api/v1/schedule", params: scope_params.merge(date: "2026-07-21"), headers: headers

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["schedule"].first["booking_request"]).to be_nil
        end

        context "with a gym member booking request" do
          let(:user) { create(:user, email: "member@example.com") }
          let(:gym_member) { create(:gym_member, email: "member@example.com") }
          let(:booking_schedule_entry) do
            create(
              :schedule_entry,
              facility: facility,
              class_type: class_type,
              date: Date.new(2026, 8, 1),
              start_time: Time.zone.parse("2026-08-01 07:00:00 UTC")
            )
          end

          it "includes null booking_request when the gym member has no request" do
            gym_member
            booking_schedule_entry

            get "/api/v1/schedule", params: scope_params.merge(date: "2026-08-01"), headers: headers

            expect(response).to have_http_status(:ok)
            expect(response.parsed_body["schedule"].first["booking_request"]).to be_nil
          end

          it "includes a pending booking_request" do
            booking_request = create(
              :booking_request,
              gym_member: gym_member,
              schedule_entry: booking_schedule_entry,
              status: :pending,
              booking_window_opens_at: Time.zone.parse("2026-07-31 07:00:00 UTC")
            )

            get "/api/v1/schedule", params: scope_params.merge(date: "2026-08-01"), headers: headers

            expect(response).to have_http_status(:ok)
            expect(response.parsed_body["schedule"].first["booking_request"]).to eq(
              "id" => booking_request.id,
              "status" => "pending",
              "booking_window_opens_at" => "2026-07-31T07:00:00Z"
            )
          end

          it "includes a booked booking_request" do
            booking_request = create(
              :booking_request,
              :booked,
              gym_member: gym_member,
              schedule_entry: booking_schedule_entry,
              booking_window_opens_at: Time.zone.parse("2026-08-01 09:00:00 UTC")
            )

            get "/api/v1/schedule", params: scope_params.merge(date: "2026-08-01"), headers: headers

            expect(response).to have_http_status(:ok)
            expect(response.parsed_body["schedule"].first["booking_request"]).to eq(
              "id" => booking_request.id,
              "status" => "booked",
              "booking_window_opens_at" => "2026-08-01T09:00:00Z"
            )
          end
        end
      end
    end
  end
end
