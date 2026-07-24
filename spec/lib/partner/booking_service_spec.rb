require "rails_helper"

RSpec.describe Partner::BookingService do
  around do |example|
    old_url    = ENV.delete("PARTNER_API_BASE_URL")
    old_origin = ENV.delete("PARTNER_AUTH_ORIGIN")
    old_referer = ENV.delete("PARTNER_AUTH_REFERER")
    ENV["PARTNER_API_BASE_URL"] = "http://partner.test"
    ENV["PARTNER_AUTH_ORIGIN"]  = "https://partner.test"
    ENV["PARTNER_AUTH_REFERER"]  = "https://partner.test"
    example.run
  ensure
    ENV["PARTNER_API_BASE_URL"] = old_url
    ENV["PARTNER_AUTH_ORIGIN"]  = old_origin
    ENV["PARTNER_AUTH_REFERER"]  = old_referer
  end

  let(:class_type)     { create(:class_type, name: "Spinning") }
  let(:facility)       { create(:facility, external_id: 84, evo_token: "evo-token-abc", name: "Downtown Gym") }
  let(:schedule_entry) do
    create(:schedule_entry,
           class_type:,
           facility:,
           date: Date.new(2026, 7, 21),
           start_time: Time.zone.parse("2026-07-21 07:00:00 UTC"),
           partner_activity_id: "act-uuid-123",
           activ_config_id: 42)
  end
  let(:gym_member) { create(:gym_member, email: "alice@example.com", password: "Password123!") }

  subject(:service) { described_class.new(schedule_entry:, gym_member:) }

  describe "#book" do
    context "when the partner API returns a successful booking" do
      let(:spot_number) { 5 }

      before do
        allow(gym_member).to receive_message_chain(:partner_tokens, :valid_tokens, :order, :first)
          .and_return(nil)

        auth_service = instance_double(Partner::AuthService, login: double(access_token: "access-token-abc"))
        allow(Partner::AuthService).to receive(:new).with(gym_member:).and_return(auth_service)

        success_response = instance_double(HTTParty::Response,
                                           success?: true,
                                           code: 200,
                                           parsed_response: {
                                             "status" => "OK",
                                             "data" => {
                                               "_id" => "booking-xyz-001",
                                               "spot_number" => spot_number
                                             },
                                             "errors" => []
                                           })
        allow(described_class).to receive(:post).and_return(success_response)
      end

      it "returns confirmation_id and spot_number" do
        result = service.book

        expect(result).to eq(confirmation_id: "booking-xyz-001", spot_number: 5)
      end

      it "posts to the partner booking endpoint with correct body" do
        service.book

        expect(described_class).to have_received(:post).with(
          "http://partner.test/api/v1/activities/booking",
          hash_including(
            body: /"activity_id":"act-uuid-123".*"activ_config_id":42.*"activity_date":"2026-07-21".*"token_branch":"evo-token-abc".*"activity_start":"2026-07-21T07:00:00Z".*"timezone":"America\/Bogota".*"activity_name":"Spinning".*"capacity":20.*"branch_name":"Downtown Gym".*"branch_id":84.*"partner_name":"EVO".*"country_code":"CO".*"booking_origin":"WEB"/,
            headers: hash_including(
              "Authorization" => "Bearer access-token-abc",
              "Origin"        => "https://partner.test",
              "Referer"       => "https://partner.test"
            )
          )
        )
      end
    end

    context "when the partner API returns a non-OK status" do
      before do
        allow(gym_member).to receive_message_chain(:partner_tokens, :valid_tokens, :order, :first)
          .and_return(nil)

        auth_service = instance_double(Partner::AuthService, login: double(access_token: "access-token-abc"))
        allow(Partner::AuthService).to receive(:new).with(gym_member:).and_return(auth_service)

        error_response = instance_double(HTTParty::Response,
                                         success?: true,
                                         code: 200,
                                         parsed_response: {
                                           "status" => "ERROR",
                                           "errors" => [
                                             { "displayable_message" => "Session is full" }
                                           ],
                                           "error" => nil,
                                           "message" => nil
                                         })
        allow(described_class).to receive(:post).and_return(error_response)
      end

      it "raises Partner::BookingError with the partner error message" do
        expect { service.book }
          .to raise_error(Partner::BookingError, "Session is full")
      end
    end

    context "when the HTTP response is not successful" do
      before do
        allow(gym_member).to receive_message_chain(:partner_tokens, :valid_tokens, :order, :first)
          .and_return(nil)

        auth_service = instance_double(Partner::AuthService, login: double(access_token: "access-token-abc"))
        allow(Partner::AuthService).to receive(:new).with(gym_member:).and_return(auth_service)

        fail_response = instance_double(HTTParty::Response,
                                        success?: false,
                                        code: 401,
                                        parsed_response: { "error" => "Unauthorized" })
        allow(described_class).to receive(:post).and_return(fail_response)
      end

      it "raises Partner::BookingError" do
        expect { service.book }
          .to raise_error(Partner::BookingError, /Unauthorized/)
      end
    end

    context "when the response is missing confirmation ID" do
      before do
        allow(gym_member).to receive_message_chain(:partner_tokens, :valid_tokens, :order, :first)
          .and_return(nil)

        auth_service = instance_double(Partner::AuthService, login: double(access_token: "access-token-abc"))
        allow(Partner::AuthService).to receive(:new).with(gym_member:).and_return(auth_service)

        incomplete_response = instance_double(HTTParty::Response,
                                              success?: true,
                                              code: 200,
                                              parsed_response: {
                                                "status" => "OK",
                                                "data" => { "spot_number" => 5 },
                                                "errors" => []
                                              })
        allow(described_class).to receive(:post).and_return(incomplete_response)
      end

      it "raises Partner::BookingError" do
        expect { service.book }
          .to raise_error(Partner::BookingError, "Missing confirmation ID in partner response")
      end
    end

    context "when the response is malformed" do
      before do
        allow(gym_member).to receive_message_chain(:partner_tokens, :valid_tokens, :order, :first)
          .and_return(nil)

        auth_service = instance_double(Partner::AuthService, login: double(access_token: "access-token-abc"))
        allow(Partner::AuthService).to receive(:new).with(gym_member:).and_return(auth_service)

        bad_response = instance_double(HTTParty::Response,
                                       success?: true,
                                       code: 200,
                                       parsed_response: "not a hash")
        allow(described_class).to receive(:post).and_return(bad_response)
      end

      it "raises Partner::BookingError" do
        expect { service.book }
          .to raise_error(Partner::BookingError, "Malformed partner response")
      end
    end

    context "when the member already has a valid partner token" do
      before do
        existing_token = create(:partner_token,
                                gym_member:,
                                access_token: "existing-access-token",
                                refresh_token: "existing-refresh-token",
                                token_expires_at: 2.hours.from_now)

        allow(gym_member).to receive_message_chain(:partner_tokens, :valid_tokens, :order, :first)
          .and_return(existing_token)

        success_response = instance_double(HTTParty::Response,
                                           success?: true,
                                           code: 200,
                                           parsed_response: {
                                             "status" => "OK",
                                             "data" => { "_id" => "booking-xyz-002", "spot_number" => 3 },
                                             "errors" => []
                                           })
        allow(described_class).to receive(:post).and_return(success_response)
      end

      it "uses the existing valid token without re-authenticating" do
        expect(Partner::AuthService).not_to receive(:new)

        result = service.book

        expect(result).to eq(confirmation_id: "booking-xyz-002", spot_number: 3)
      end
    end

    context "when the partner returns errors with description fallback" do
      before do
        allow(gym_member).to receive_message_chain(:partner_tokens, :valid_tokens, :order, :first)
          .and_return(nil)

        auth_service = instance_double(Partner::AuthService, login: double(access_token: "access-token-abc"))
        allow(Partner::AuthService).to receive(:new).with(gym_member:).and_return(auth_service)

        error_response = instance_double(HTTParty::Response,
                                         success?: true,
                                         code: 200,
                                         parsed_response: {
                                           "status" => "ERROR",
                                           "errors" => [
                                             { "description" => "Outside booking window" }
                                           ]
                                         })
        allow(described_class).to receive(:post).and_return(error_response)
      end

      it "falls back to description when displayable_message is absent" do
        expect { service.book }
          .to raise_error(Partner::BookingError, "Outside booking window")
      end
    end

    context "when errors array has neither displayable_message nor description" do
      before do
        allow(gym_member).to receive_message_chain(:partner_tokens, :valid_tokens, :order, :first)
          .and_return(nil)

        auth_service = instance_double(Partner::AuthService, login: double(access_token: "access-token-abc"))
        allow(Partner::AuthService).to receive(:new).with(gym_member:).and_return(auth_service)

        error_response = instance_double(HTTParty::Response,
                                         success?: true,
                                         code: 200,
                                         parsed_response: {
                                           "status" => "ERROR",
                                           "errors" => [
                                             { "code" => "ALREADY_BOOKED" },
                                             { "code" => "CONFLICT" }
                                           ]
                                         })
        allow(described_class).to receive(:post).and_return(error_response)
      end

      it "joins the raw errors array" do
        expect { service.book }
          .to raise_error(Partner::BookingError, /ALREADY_BOOKED/)
      end
    end
  end
end
