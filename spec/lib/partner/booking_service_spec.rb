# frozen_string_literal: true

require "rails_helper"

RSpec.describe Partner::BookingService do
  around do |example|
    old_url     = ENV.delete("PARTNER_API_BASE_URL")
    old_referer = ENV.delete("PARTNER_AUTH_REFERER")
    old_origin  = ENV.delete("PARTNER_AUTH_ORIGIN")
    old_attr    = ENV.delete("ATTR_ENCRYPTED_KEY")

    ENV["PARTNER_API_BASE_URL"] = "http://partner.test"
    ENV["PARTNER_AUTH_REFERER"] = "https://referer.test"
    ENV["PARTNER_AUTH_ORIGIN"]  = "https://origin.test"
    ENV["ATTR_ENCRYPTED_KEY"]   = "a" * 32

    example.run
  ensure
    ENV["PARTNER_API_BASE_URL"] = old_url
    ENV["PARTNER_AUTH_REFERER"] = old_referer
    ENV["PARTNER_AUTH_ORIGIN"]  = old_origin
    ENV["ATTR_ENCRYPTED_KEY"]   = old_attr
  end

  let(:gym_member) { create(:gym_member) }
  let(:facility)   { create(:facility, external_id: 42, name: "Test Branch", evo_token: "evo-abc") }
  let(:class_type) { create(:class_type, name: "Spinning") }
  let(:schedule_entry) do
    create(:schedule_entry,
           facility:            facility,
           class_type:          class_type,
           partner_activity_id: "act-001",
           activ_config_id:     7,
           date:                Date.new(2026, 7, 21),
           start_time:          Time.zone.parse("2026-07-21 07:00:00 UTC"))
  end

  subject(:service) { described_class.new(gym_member:) }

  describe "#book" do
    context "when the partner token is missing or expired" do
      before { allow(gym_member).to receive(:password).and_return("") }

      it "raises AuthenticationError when member cannot authenticate" do
        expect { service.book(schedule_entry:) }
          .to raise_error(Partner::AuthenticationError, "Missing partner password")
      end
    end

    context "with a valid partner token" do
      let!(:partner_token) do
        create(:partner_token, gym_member: gym_member, access_token: "token-secret-abc",
               token_expires_at: 1.hour.from_now)
      end

      it "uses the gym member's latest valid partner token for auth" do
        success_response = instance_double(HTTParty::Response,
                                           success?: true,
                                           code: 200,
                                           parsed_response: {
                                             "status" => "OK",
                                             "data"   => { "_id" => "conf-99", "spot_number" => 3 },
                                             "errors" => []
                                           })
        allow(described_class).to receive(:post).and_return(success_response)

        service.book(schedule_entry:)

        expect(described_class).to have_received(:post).with(
          anything,
          hash_including(headers: hash_including("Authorization" => "Bearer token-secret-abc"))
        )
      end

      it "posts the correct booking body to the partner endpoint" do
        success_response = instance_double(HTTParty::Response,
                                           success?: true,
                                           code: 200,
                                           parsed_response: {
                                             "status" => "OK",
                                             "data"   => { "_id" => "conf-99", "spot_number" => 3 },
                                             "errors" => []
                                           })
        allow(described_class).to receive(:post).and_return(success_response)

        service.book(schedule_entry:)

        expect(described_class).to have_received(:post).with(
          "http://partner.test/api/v1/activities/booking",
          hash_including(
            body: a_string_including(
              '"activity_id":"act-001"',
              '"activ_config_id":7',
              '"activity_date":"2026-07-21T07:00:00Z"',
              '"token_branch":"evo-abc"',
              '"activity_start":"07:00"',
              '"timezone":"America/Bogota"',
              '"activity_name":"Spinning"',
              '"capacity":20',
              '"branch_name":"Test Branch"',
              '"branch_id":"42"',
              '"partner_name":"EVO"',
              '"country_code":"CO"',
              '"booking_origin":"WEB"'
            ),
            headers: hash_including(
              "Origin"  => "https://origin.test",
              "Referer" => "https://referer.test"
            )
          )
        )
      end

      it "returns confirmation_id and spot_number on success" do
        success_response = instance_double(HTTParty::Response,
                                           success?: true,
                                           code: 200,
                                           parsed_response: {
                                             "status" => "OK",
                                             "data"   => { "_id" => "conf-99", "spot_number" => 3 },
                                             "errors" => []
                                           })
        allow(described_class).to receive(:post).and_return(success_response)

        result = service.book(schedule_entry:)

        expect(result).to eq(confirmation_id: "conf-99", spot_number: "3")
      end

      it "raises BookingError when response is not successful" do
        fail_response = instance_double(HTTParty::Response,
                                        success?: false,
                                        code: 500,
                                        parsed_response: { "error" => "Internal server error" })
        allow(described_class).to receive(:post).and_return(fail_response)

        expect { service.book(schedule_entry:) }
          .to raise_error(Partner::BookingError, /Internal server error/)
      end

      it "raises BookingError when payload status is ERROR" do
        error_response = instance_double(HTTParty::Response,
                                         success?: true,
                                         code: 200,
                                         parsed_response: {
                                           "status" => "ERROR",
                                           "error"  => "Slot already taken"
                                         })
        allow(described_class).to receive(:post).and_return(error_response)

        expect { service.book(schedule_entry:) }
          .to raise_error(Partner::BookingError, /Slot already taken/)
      end

      it "extracts displayable_message from partner errors array" do
        error_response = instance_double(HTTParty::Response,
                                         success?: true,
                                         code: 200,
                                         parsed_response: {
                                           "status" => "ERROR",
                                           "errors" => [
                                             {
                                               "displayable_message" => "This class is fully booked",
                                               "description"         => "No available spots"
                                             }
                                           ]
                                         })
        allow(described_class).to receive(:post).and_return(error_response)

        expect { service.book(schedule_entry:) }
          .to raise_error(Partner::BookingError, "This class is fully booked")
      end

      it "raises BookingError on malformed JSON response" do
        malformed_response = instance_double(HTTParty::Response,
                                             success?: true,
                                             code: 200,
                                             parsed_response: "not a hash")
        allow(described_class).to receive(:post).and_return(malformed_response)

        expect { service.book(schedule_entry:) }
          .to raise_error(Partner::BookingError, "Malformed partner response")
      end
    end
  end
end
