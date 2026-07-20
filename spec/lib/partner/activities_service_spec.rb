# frozen_string_literal: true

require "rails_helper"

RSpec.describe Partner::ActivitiesService do
  around do |example|
    old_url     = ENV.delete("PARTNER_API_BASE_URL")
    old_referer = ENV.delete("PARTNER_AUTH_REFERER")
    old_origin  = ENV.delete("PARTNER_AUTH_ORIGIN")
    old_token   = ENV.delete("PARTNER_ACTIVITIES_TOKEN")

    ENV["PARTNER_API_BASE_URL"]      = "http://partner.test"
    ENV["PARTNER_AUTH_REFERER"]      = "https://referer.test"
    ENV["PARTNER_AUTH_ORIGIN"]       = "https://origin.test"
    ENV["PARTNER_ACTIVITIES_TOKEN"]  = "test-token"

    example.run
  ensure
    ENV["PARTNER_API_BASE_URL"]     = old_url
    ENV["PARTNER_AUTH_REFERER"]     = old_referer
    ENV["PARTNER_AUTH_ORIGIN"]      = old_origin
    ENV["PARTNER_ACTIVITIES_TOKEN"] = old_token
  end

  subject(:service) { described_class.new }

  let(:facility) { create(:facility, external_id: 1, evo_token: "evo-abc") }

  let(:successful_payload) do
    {
      "status" => "OK",
      "data" => [
        {
          "name"       => "Spinning",
          "branch_id"  => 1,
          "start_time" => "2026-07-21T07:00:00Z",
          "date"       => "2026-07-21"
        },
        {
          "name"       => "Yoga",
          "branch_id"  => 99,
          "start_time" => "2026-07-21T08:00:00Z",
          "date"       => "2026-07-21"
        }
      ]
    }
  end

  let(:date) { Date.new(2026, 7, 21) }

  describe "#fetch" do
    context "with successful response" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: successful_payload)
        allow(described_class).to receive(:get).and_return(response)
      end

      it "creates Activity and ScheduleEntry records" do
        entries = service.fetch(facility:, date:)

        expect(Activity.count).to eq(2)
        activity = Activity.find_by(name: "Spinning")
        expect(activity).to be_present

        expect(ScheduleEntry.count).to eq(1)
        entry = ScheduleEntry.first
        expect(entry.facility).to eq(facility)
        expect(entry.activity).to eq(activity)
        expect(entry.start_time).to eq("2026-07-21T07:00:00Z")
        expect(entry.date).to eq(Date.new(2026, 7, 21))

        expect(entries).to be_an(Array)
        expect(entries.length).to eq(1)
        expect(entries.first).to eq(entry)
      end

      it "skips ScheduleEntry creation for unmatched branch_id" do
        entries = service.fetch(facility:, date:)

        expect(Activity.count).to eq(2)
        expect(Activity.find_by(name: "Yoga")).to be_present
        expect(ScheduleEntry.count).to eq(1)
        expect(entries.length).to eq(1)
      end
    end

    context "is idempotent — re-fetching with same data does not duplicate rows" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: successful_payload)
        allow(described_class).to receive(:get).and_return(response)
      end

      it "does not duplicate rows on second fetch" do
        first_entries  = service.fetch(facility:, date:)
        second_entries = service.fetch(facility:, date:)

        expect(Activity.count).to eq(2)
        expect(ScheduleEntry.count).to eq(1)
        expect(first_entries.length).to eq(1)
        expect(second_entries.length).to eq(1)
        expect(first_entries.first).to eq(second_entries.first)
      end
    end

    context "when the response body has status ERROR" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: {
                                     "status" => "ERROR",
                                     "error"  => "Invalid parameters"
                                   })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "raises Partner::ActivitiesError" do
        expect { service.fetch(facility:, date:) }
          .to raise_error(Partner::ActivitiesError, /Invalid parameters/)
      end
    end

    context "when the HTTP response is non-2xx" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: false,
                                   code: 401,
                                   parsed_response: { "error" => "Unauthorized" })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "raises Partner::ActivitiesError" do
        expect { service.fetch(facility:, date:) }
          .to raise_error(Partner::ActivitiesError, /Unauthorized/)
      end
    end

    context "with malformed JSON (non-Hash body)" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: "not a json hash")
        allow(described_class).to receive(:get).and_return(response)
      end

      it "raises Partner::ActivitiesError" do
        expect { service.fetch(facility:, date:) }
          .to raise_error(Partner::ActivitiesError, "Malformed partner response")
      end
    end

    context "when the response is missing a data key" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: { "status" => "OK" })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "raises Partner::ActivitiesError" do
        expect { service.fetch(facility:, date:) }
          .to raise_error(Partner::ActivitiesError, "Missing data array in partner response")
      end
    end
  end
end
