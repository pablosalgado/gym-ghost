require "rails_helper"

RSpec.describe SyncFacilitiesJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:service) { instance_double(Partner::FacilitiesService) }

    before do
      allow(Partner::FacilitiesService).to receive(:new).and_return(service)
      allow(service).to receive(:sync)
    end

    it "delegates to Partner::FacilitiesService#sync exactly once" do
      perform_enqueued_jobs do
        described_class.perform_later
      end

      expect(Partner::FacilitiesService).to have_received(:new).once
      expect(service).to have_received(:sync).once
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
