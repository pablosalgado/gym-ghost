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
          "activity_name" => "Spinning",
          "branch_id"     => 1,
          "activity_id"   => "act-uuid-001",
          "activ_config_id" => 100,
          "start_time"    => "2026-07-21T07:00:00Z",
          "date"          => "2026-07-21"
        },
        {
          "activity_name" => "Yoga",
          "branch_id"     => 99,
          "activity_id"   => "act-uuid-002",
          "activ_config_id" => 200,
          "start_time"    => "2026-07-21T08:00:00Z",
          "date"          => "2026-07-21"
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

      it "creates ClassType and ScheduleEntry records with partner activity identifiers" do
        entries = service.fetch(facility:, date:)

        expect(ClassType.count).to eq(2)
        class_type = ClassType.find_by(name: "Spinning")
        expect(class_type).to be_present

        expect(ScheduleEntry.count).to eq(1)
        entry = ScheduleEntry.first
        expect(entry.facility).to eq(facility)
        expect(entry.class_type).to eq(class_type)
        expect(entry.start_time).to eq("2026-07-21T07:00:00Z")
        expect(entry.date).to eq(Date.new(2026, 7, 21))
        expect(entry.partner_activity_id).to eq("act-uuid-001")
        expect(entry.activ_config_id).to eq(100)

        expect(entries).to be_an(Array)
        expect(entries.length).to eq(1)
        expect(entries.first).to eq(entry)
      end

      it "skips ScheduleEntry creation for unmatched branch_id" do
        entries = service.fetch(facility:, date:)

        expect(ClassType.count).to eq(2)
        expect(ClassType.find_by(name: "Yoga")).to be_present
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

        expect(ClassType.count).to eq(2)
        expect(ScheduleEntry.count).to eq(1)
        expect(first_entries.length).to eq(1)
        expect(second_entries.length).to eq(1)
        expect(first_entries.first).to eq(second_entries.first)
      end
    end

    context "when partner response omits activity identifiers" do
      let(:payload_without_ids) do
        {
          "status" => "OK",
          "data" => [
            {
              "activity_name" => "Spinning",
              "branch_id"     => 1,
              "start_time"    => "2026-07-21T07:00:00Z",
              "date"          => "2026-07-21"
            }
          ]
        }
      end

      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: payload_without_ids)
        allow(described_class).to receive(:get).and_return(response)
      end

      it "stores nil for partner_activity_id and activ_config_id" do
        entries = service.fetch(facility:, date:)

        entry = entries.first
        expect(entry.partner_activity_id).to be_nil
        expect(entry.activ_config_id).to be_nil
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

    context "with a mixed payload (holiday and non-holiday items)" do
      let(:holiday_date) { Date.new(2026, 7, 20) }
      let(:sunday_date)  { Date.new(2026, 7, 19) }

      let(:mixed_payload) do
        {
          "status" => "OK",
          "data" => [
            {
              "activity_name" => "Spinning",
              "branch_id"     => 1,
              "activity_id"   => "act-uuid-001",
              "activ_config_id" => 100,
              "start_time"    => "2026-07-21T07:00:00Z",
              "date"          => "2026-07-21"
            },
            {
              "activity_name" => "Yoga",
              "branch_id"     => 1,
              "activity_id"   => "act-uuid-002",
              "activ_config_id" => 200,
              "start_time"    => "2026-07-20T08:00:00Z",
              "date"          => "2026-07-20"
            }
          ]
        }
      end

      let!(:sunday_entry) do
        sunday_ct = create(:class_type, name: "Spinning")
        create(:schedule_entry,
               facility: facility,
               class_type: sunday_ct,
               start_time: Time.zone.parse("2026-07-19T07:00:00Z"),
               date: sunday_date,
               partner_activity_id: "act-sunday-001",
               activ_config_id: 999)
      end

      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: mixed_payload)
        allow(described_class).to receive(:get).and_return(response)
        allow(HolidayService).to receive(:holiday?).and_return(false)
        allow(HolidayService).to receive(:holiday?).with(holiday_date).and_return(true)
      end

      it "processes non-holiday items normally" do
        entries = service.fetch(facility:, date:)

        non_holiday = entries.find { |e| e.date == Date.new(2026, 7, 21) }
        expect(non_holiday).to be_present
        expect(non_holiday.class_type.name).to eq("Spinning")
      end

      it "skips holiday items — no partner data inserted for the holiday date" do
        service.fetch(facility:, date:)

        holiday_entries = ScheduleEntry.where(facility:, date: holiday_date)
        expect(holiday_entries.count).to eq(1)
        expect(holiday_entries.first.partner_activity_id).to eq("act-sunday-001")
      end

      it "backfills from the last Sunday for the holiday date" do
        service.fetch(facility:, date:)

        backfilled = ScheduleEntry.find_by(facility:, date: holiday_date)
        expect(backfilled).to be_present
        expect(backfilled.class_type).to eq(sunday_entry.class_type)
        expect(backfilled.partner_activity_id).to eq(sunday_entry.partner_activity_id)
        expect(backfilled.activ_config_id).to eq(sunday_entry.activ_config_id)
        expect(backfilled.start_time).to eq(
          sunday_entry.start_time.change(
            year: holiday_date.year, month: holiday_date.month, day: holiday_date.day
          )
        )
      end

      it "is idempotent — re-fetching does not duplicate backfill rows" do
        service.fetch(facility:, date:)
        service.fetch(facility:, date:)

        expect(ScheduleEntry.where(facility:, date: holiday_date).count).to eq(1)
      end

      it "returns entries only for non-holiday items (backfilled entries excluded)" do
        entries = service.fetch(facility:, date:)
        expect(entries.length).to eq(1)
        expect(entries.first.date).to eq(Date.new(2026, 7, 21))
      end
    end

    context "when the last Sunday has no entries" do
      let(:holiday_only_payload) do
        {
          "status" => "OK",
          "data" => [
            {
              "activity_name" => "Spinning",
              "branch_id"     => 1,
              "activity_id"   => "act-uuid-001",
              "activ_config_id" => 100,
              "start_time"    => "2026-07-20T07:00:00Z",
              "date"          => "2026-07-20"
            }
          ]
        }
      end

      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: holiday_only_payload)
        allow(described_class).to receive(:get).and_return(response)
        allow(HolidayService).to receive(:holiday?).and_return(false)
        allow(HolidayService).to receive(:holiday?).with(Date.new(2026, 7, 20)).and_return(true)
      end

      it "skips the holiday item silently without raising an error" do
        expect { service.fetch(facility:, date:) }.not_to raise_error
      end

      it "does not create any backfill entries" do
        service.fetch(facility:, date:)
        expect(ScheduleEntry.where(facility:, date: Date.new(2026, 7, 20))).to be_empty
      end
    end

    context "when the last Sunday is also a holiday" do
      let(:holiday_date)  { Date.new(2026, 7, 20) }
      let(:sunday_date)   { Date.new(2026, 7, 19) }
      let(:saturday_date) { Date.new(2026, 7, 18) }

      let(:holiday_only_payload) do
        {
          "status" => "OK",
          "data" => [
            {
              "activity_name" => "Spinning",
              "branch_id"     => 1,
              "activity_id"   => "act-uuid-001",
              "activ_config_id" => 100,
              "start_time"    => "2026-07-20T07:00:00Z",
              "date"          => "2026-07-20"
            }
          ]
        }
      end

      let!(:saturday_entry) do
        ct = create(:class_type, name: "Spinning")
        create(:schedule_entry,
               facility: facility,
               class_type: ct,
               start_time: Time.zone.parse("2026-07-18T07:00:00Z"),
               date: saturday_date,
               partner_activity_id: "act-sat-001",
               activ_config_id: 888)
      end

      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: holiday_only_payload)
        allow(described_class).to receive(:get).and_return(response)
        allow(HolidayService).to receive(:holiday?).and_return(false)
        allow(HolidayService).to receive(:holiday?).with(holiday_date).and_return(true)
        allow(HolidayService).to receive(:holiday?).with(sunday_date).and_return(true)
      end

      it "walks back day-by-day and copies entries from the first non-holiday source" do
        service.fetch(facility:, date: holiday_date)

        backfilled = ScheduleEntry.find_by(facility:, date: holiday_date)
        expect(backfilled).to be_present
        expect(backfilled.class_type).to eq(saturday_entry.class_type)
        expect(backfilled.partner_activity_id).to eq(saturday_entry.partner_activity_id)
        expect(backfilled.start_time).to eq(
          saturday_entry.start_time.change(
            year: holiday_date.year, month: holiday_date.month, day: holiday_date.day
          )
        )
      end
    end

    context "when an item has no date (falls back to the date parameter)" do
      let(:payload_without_item_date) do
        {
          "status" => "OK",
          "data" => [
            {
              "activity_name" => "Spinning",
              "branch_id"     => 1,
              "activity_id"   => "act-uuid-001",
              "activ_config_id" => 100,
              "start_time"    => "2026-07-21T07:00:00Z"
            }
          ]
        }
      end

      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: payload_without_item_date)
        allow(described_class).to receive(:get).and_return(response)
        allow(HolidayService).to receive(:holiday?).and_return(false)
      end

      it "uses the date parameter and processes normally when not a holiday" do
        entries = service.fetch(facility:, date:)
        expect(entries.length).to eq(1)
        expect(entries.first.date).to eq(date)
      end

      it "skips the item when the date parameter is a holiday" do
        allow(HolidayService).to receive(:holiday?).with(date).and_return(true)

        entries = service.fetch(facility:, date:)
        expect(entries).to be_empty
      end
    end

    context "concurrency locking" do
      before do
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        Rails.cache.clear
      end

      it "skips fetching and returns existing local entries when cache lock already exists" do
        Rails.cache.write("schedule_load:#{facility.id}:#{date}", true)
        existing_entry = create(:schedule_entry, facility: facility, date: date)

        expect(described_class).not_to receive(:get)
        entries = service.fetch(facility:, date:)

        expect(entries).to eq([ existing_entry ])
      end

      it "clears cache lock in ensure block even when fetching raises an error" do
        allow(described_class).to receive(:get).and_raise(StandardError.new("Network error"))

        expect { service.fetch(facility:, date:) }.to raise_error(StandardError, /Network error/)
        expect(Rails.cache.exist?("schedule_load:#{facility.id}:#{date}")).to be false
      end
    end
  end
end
