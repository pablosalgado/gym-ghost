require "rails_helper"

RSpec.describe FetchScheduleEntriesJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:facility) { create(:facility) }
    let(:date)     { "2026-07-23" }
    let(:service)  { instance_double(Partner::ActivitiesService) }

    before do
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      Rails.cache.clear

      allow(Partner::ActivitiesService).to receive(:new).and_return(service)
      allow(service).to receive(:fetch)
    end

    it "delegates to Partner::ActivitiesService#fetch with correct args and sets cache lock" do
      perform_enqueued_jobs do
        described_class.perform_later(facility.id, date)
      end

      expect(Partner::ActivitiesService).to have_received(:new).once
      expect(service).to have_received(:fetch)
        .with(facility: facility, date: date).once
      expect(Rails.cache.exist?("schedule_load:#{facility.id}:#{date}")).to be true
    end

    it "skips fetching when cache lock already exists (preventing concurrent fetches)" do
      Rails.cache.write("schedule_load:#{facility.id}:#{date}", true)

      perform_enqueued_jobs do
        described_class.perform_later(facility.id, date)
      end

      expect(Partner::ActivitiesService).not_to have_received(:new)
      expect(service).not_to have_received(:fetch)
    end

    it "rescues Partner::ActivitiesError and logs a warning without retrying" do
      allow(service).to receive(:fetch)
        .and_raise(Partner::ActivitiesError.new("API timeout"))

      expect(Rails.logger).to receive(:warn)
        .with(/FetchScheduleEntriesJob failed/)

      expect do
        perform_enqueued_jobs do
          described_class.perform_later(facility.id, date)
        end
      end.not_to raise_error

      expect(Rails.cache.exist?("schedule_load:#{facility.id}:#{date}")).to be true
    end
  end

  describe "enqueue" do
    it "enqueues on the default queue" do
      described_class.perform_later(1, "2026-07-23")

      expect(enqueued_jobs.size).to eq(1)
      expect(enqueued_jobs.first[:job]).to eq(described_class)
      expect(enqueued_jobs.first[:queue]).to eq("default")
    end
  end
end
