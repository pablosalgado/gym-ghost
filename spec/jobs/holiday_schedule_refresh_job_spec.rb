require "rails_helper"

RSpec.describe HolidayScheduleRefreshJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:tomorrow)     { Date.new(2026, 7, 20) }
    let(:facility)     { create(:facility) }
    let(:class_type)   { create(:class_type) }
    let(:gym_member)   { create(:gym_member) }

    before do
      travel_to Time.zone.parse("2026-07-19 05:05:00 UTC")
    end

    context "when tomorrow is not a holiday" do
      before do
        allow(HolidayService).to receive(:holiday?).with(tomorrow).and_return(false)
        allow(Rails.logger).to receive(:info)
      end

      it "logs and returns without doing any work" do
        perform_enqueued_jobs do
          described_class.perform_later
        end

        expect(Rails.logger).to have_received(:info).with(/not a holiday/)
        expect(Partner::ActivitiesService).not_to receive(:new)
      end
    end

    context "when tomorrow is a holiday" do
      before do
        allow(HolidayService).to receive(:holiday?).with(tomorrow).and_return(true)
      end

      context "with no booking requests for that date" do
        before do
          allow(Rails.logger).to receive(:info)
        end

        it "logs and returns without processing any facilities" do
          perform_enqueued_jobs do
            described_class.perform_later
          end

          expect(Rails.logger).to have_received(:info).with(/no booking requests/)
        end
      end

      context "with booking requests for that date" do
        let(:service) { instance_double(Partner::ActivitiesService) }
        let!(:schedule_entry) do
          create(:schedule_entry, facility: facility, class_type: class_type, date: tomorrow)
        end
        let!(:booking_request) do
          create(:booking_request, schedule_entry: schedule_entry, gym_member: gym_member)
        end

        before do
          allow(Partner::ActivitiesService).to receive(:new).and_return(service)
          allow(service).to receive(:fetch).and_return([])
          allow(Rails.logger).to receive(:info)
        end

        it "calls ActivitiesService#fetch for the facility" do
          perform_enqueued_jobs do
            described_class.perform_later
          end

          expect(Partner::ActivitiesService).to have_received(:new).once
          expect(service).to have_received(:fetch)
            .with(facility: facility, date: tomorrow).once
        end

        it "logs entry count after refresh" do
          perform_enqueued_jobs do
            described_class.perform_later
          end

          expect(Rails.logger).to have_received(:info).with(/entries refreshed/)
        end

        it "updates activ_config_id from returned entries" do
          returned = build(:schedule_entry,
            facility: facility,
            class_type: class_type,
            date: tomorrow,
            start_time: schedule_entry.start_time,
            activ_config_id: 99)
          allow(service).to receive(:fetch).and_return([ returned ])

          perform_enqueued_jobs do
            described_class.perform_later
          end

          expect(schedule_entry.reload.activ_config_id).to eq(99)
        end
      end

      context "with multiple facilities" do
        let(:facility2)   { create(:facility) }
        let(:service)     { instance_double(Partner::ActivitiesService) }
        let!(:entry1)     { create(:schedule_entry, facility: facility, date: tomorrow) }
        let!(:entry2)     { create(:schedule_entry, facility: facility2, date: tomorrow) }
        let!(:br1)        { create(:booking_request, schedule_entry: entry1, gym_member: gym_member) }
        let!(:br2)        { create(:booking_request, schedule_entry: entry2, gym_member: gym_member) }

        before do
          allow(Partner::ActivitiesService).to receive(:new).and_return(service)
          allow(service).to receive(:fetch).and_return([])
        end

        it "calls fetch for each unique facility" do
          perform_enqueued_jobs do
            described_class.perform_later
          end

          expect(Partner::ActivitiesService).to have_received(:new).twice
          expect(service).to have_received(:fetch)
            .with(facility: facility, date: tomorrow).once
          expect(service).to have_received(:fetch)
            .with(facility: facility2, date: tomorrow).once
        end
      end

      context "with duplicate booking requests for the same facility" do
        let(:service) { instance_double(Partner::ActivitiesService) }
        let!(:entry)  { create(:schedule_entry, facility: facility, date: tomorrow) }
        let!(:br1)    { create(:booking_request, schedule_entry: entry, gym_member: gym_member) }
        let!(:br2)    { create(:booking_request, schedule_entry: entry, gym_member: create(:gym_member)) }

        before do
          allow(Partner::ActivitiesService).to receive(:new).and_return(service)
          allow(service).to receive(:fetch).and_return([])
        end

        it "deduplicates facilities and calls fetch only once per facility" do
          perform_enqueued_jobs do
            described_class.perform_later
          end

          expect(Partner::ActivitiesService).to have_received(:new).once
          expect(service).to have_received(:fetch)
            .with(facility: facility, date: tomorrow).once
        end
      end

      context "when ActivitiesService#fetch raises an error" do
        let(:service) { instance_double(Partner::ActivitiesService) }
        let!(:schedule_entry) do
          create(:schedule_entry, facility: facility, class_type: class_type, date: tomorrow)
        end
        let!(:booking_request) do
          create(:booking_request, schedule_entry: schedule_entry, gym_member: gym_member)
        end

        before do
          allow(Partner::ActivitiesService).to receive(:new).and_return(service)
          allow(service).to receive(:fetch)
            .and_raise(Partner::ActivitiesError.new("API timeout"))
          allow(Rails.logger).to receive(:warn)
        end

        it "logs a warning and does not re-raise" do
          expect do
            perform_enqueued_jobs do
              described_class.perform_later
            end
          end.not_to raise_error

          expect(Rails.logger).to have_received(:warn)
            .with(/HolidayScheduleRefreshJob.*failed/)
        end

        it "does not retry on failure" do
          perform_enqueued_jobs do
            described_class.perform_later
          end

          expect(enqueued_jobs.size).to eq(0)
        end
      end
    end
  end

  describe "enqueue" do
    it "enqueues on the default queue" do
      described_class.perform_later

      expect(enqueued_jobs.size).to eq(1)
      expect(enqueued_jobs.first[:job]).to eq(described_class)
      expect(enqueued_jobs.first[:queue]).to eq("default")
    end
  end
end
