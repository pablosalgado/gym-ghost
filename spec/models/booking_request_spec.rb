require 'rails_helper'

RSpec.describe BookingRequest, type: :model do
  it 'is valid with valid attributes' do
    expect(build(:booking_request)).to be_valid
  end

  it 'is persisted after create' do
    booking_request = create(:booking_request)

    expect(booking_request).to be_persisted
    expect(booking_request.status).to eq('pending')
    expect(booking_request.booking_window_opens_at).to be_present
  end

  describe 'associations' do
    it 'belongs to a gym_member' do
      expect(BookingRequest.reflect_on_association(:gym_member).macro).to eq(:belongs_to)
    end

    it 'belongs to a schedule_entry' do
      expect(BookingRequest.reflect_on_association(:schedule_entry).macro).to eq(:belongs_to)
    end

    it 'requires a gym_member' do
      booking_request = build(:booking_request, gym_member: nil)

      expect(booking_request).not_to be_valid
      expect(booking_request.errors[:gym_member]).to include('must exist')
    end

    it 'requires a schedule_entry' do
      booking_request = build(:booking_request, schedule_entry: nil)

      expect(booking_request).not_to be_valid
      expect(booking_request.errors[:schedule_entry]).to include('must exist')
    end
  end

  describe 'validations' do
    it 'requires a booking_window_opens_at' do
      booking_request = build(:booking_request, booking_window_opens_at: nil)

      expect(booking_request).not_to be_valid
      expect(booking_request.errors[:booking_window_opens_at]).to include("can't be blank")
    end
  end

  describe 'status enum' do
    it 'defaults to pending' do
      expect(build(:booking_request).status).to eq('pending')
    end

    it 'has pending, booked, and failed values' do
      expect(BookingRequest.statuses).to eq(
        'pending' => 0,
        'booked' => 1,
        'failed' => 2
      )
    end

    it 'validates inclusion of status' do
      expect { build(:booking_request, status: :pending) }.not_to raise_error
      expect { build(:booking_request, status: :booked) }.not_to raise_error
      expect { build(:booking_request, status: :failed) }.not_to raise_error
      expect { build(:booking_request, status: :invalid) }.to raise_error(ArgumentError)
    end

    it 'returns pending? correctly' do
      expect(build(:booking_request, status: :pending)).to be_pending
      expect(build(:booking_request, status: :booked)).not_to be_pending
    end

    it 'returns booked? correctly' do
      expect(build(:booking_request, status: :booked)).to be_booked
      expect(build(:booking_request, status: :pending)).not_to be_booked
    end

    it 'returns failed? correctly' do
      expect(build(:booking_request, status: :failed)).to be_failed
      expect(build(:booking_request, status: :pending)).not_to be_failed
    end
  end

  describe 'unique index constraint' do
    it 'prevents duplicate active requests for the same member and schedule entry' do
      member = create(:gym_member)
      entry = create(:schedule_entry)

      create(:booking_request, gym_member: member, schedule_entry: entry, status: :pending)

      duplicate = build(:booking_request, gym_member: member, schedule_entry: entry, status: :pending)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows a failed request alongside a pending request for the same member and entry' do
      member = create(:gym_member)
      entry = create(:schedule_entry)

      create(:booking_request, gym_member: member, schedule_entry: entry, status: :pending)
      failed = build(:booking_request, gym_member: member, schedule_entry: entry, status: :failed)

      expect(failed.save(validate: false)).to be_truthy
    end
  end

  describe 'schedule_entry has_many booking_requests' do
    it 'prevents deletion when booking_requests exist' do
      booking_request = create(:booking_request)

      expect(booking_request.schedule_entry.destroy).to be false
      expect(booking_request.schedule_entry.errors[:base]).to include(
        "Cannot delete record because dependent booking requests exist"
      )
    end
  end
end
