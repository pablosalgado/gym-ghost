require "rails_helper"

RSpec.describe BookingRequestJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:gym_member)     { create(:gym_member) }
    let(:facility)       { create(:facility) }
    let(:class_type)     { create(:class_type) }
    let(:schedule_entry) { create(:schedule_entry, facility:, class_type:) }
    let(:booking_request) { create(:booking_request, gym_member:, schedule_entry:) }
    let(:service) { instance_double(Partner::BookingService) }

    before do
      allow(Partner::BookingService).to receive(:new)
        .with(gym_member: gym_member)
        .and_return(service)
      allow(service).to receive(:book)
        .with(schedule_entry: schedule_entry)
        .and_return({ confirmation_id: "conf-xyz", spot_number: "3" })
    end

    it "calls Partner::BookingService#book with the request's gym_member and schedule_entry" do
      perform_enqueued_jobs do
        described_class.perform_later(booking_request.id)
      end

      expect(Partner::BookingService).to have_received(:new)
        .with(gym_member: gym_member).once
      expect(service).to have_received(:book)
        .with(schedule_entry: schedule_entry).once
    end

    it "marks the request as booked and stores partner_confirmation_id on success" do
      perform_enqueued_jobs do
        described_class.perform_later(booking_request.id)
      end

      booking_request.reload
      expect(booking_request.status).to eq("booked")
      expect(booking_request.partner_confirmation_id).to eq("conf-xyz")
    end

    it "marks the request as failed and stores error_message on BookingError" do
      allow(service).to receive(:book)
        .with(schedule_entry: schedule_entry)
        .and_raise(Partner::BookingError.new("Booking window closed"))

      perform_enqueued_jobs do
        described_class.perform_later(booking_request.id)
      end

      booking_request.reload
      expect(booking_request.status).to eq("failed")
      expect(booking_request.error_message).to eq("Booking window closed")
    end

    it "skips processing when the request is already booked (idempotency)" do
      already_booked = create(:booking_request, :booked, gym_member:, schedule_entry:)

      perform_enqueued_jobs do
        described_class.perform_later(already_booked.id)
      end

      expect(Partner::BookingService).not_to have_received(:new)
      already_booked.reload
      expect(already_booked.status).to eq("booked")
    end

    it "does not retry on failure" do
      allow(service).to receive(:book)
        .with(schedule_entry: schedule_entry)
        .and_raise(Partner::BookingError.new("API timeout"))

      expect do
        perform_enqueued_jobs do
          described_class.perform_later(booking_request.id)
        end
      end.not_to raise_error

      booking_request.reload
      expect(booking_request.status).to eq("failed")
    end
  end

  describe "enqueue" do
    it "enqueues on the default queue" do
      described_class.perform_later(1)

      expect(enqueued_jobs.size).to eq(1)
      expect(enqueued_jobs.first[:job]).to eq(described_class)
      expect(enqueued_jobs.first[:queue]).to eq("default")
    end
  end
end
