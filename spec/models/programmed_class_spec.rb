require 'rails_helper'

RSpec.describe ProgrammedClass, type: :model do
  subject(:programmed_class) { build(:programmed_class) }

  describe 'associations' do
    it { should belong_to(:schedule) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:status) }
    it { should validate_uniqueness_of(:schedule_id).scoped_to(:user_id) }
  end

  describe 'enums' do
    it 'defines status values' do
      expect(described_class.statuses).to eq(
        "programmed" => "programmed",
        "reserved" => "reserved",
        "canceled" => "canceled",
        "failed" => "failed"
      )
    end
  end

  describe 'delegations' do
    it { should delegate_method(:start_time).to(:schedule) }
    it { should delegate_method(:class_type).to(:schedule) }
    it { should delegate_method(:facility).to(:schedule) }
  end

  describe '.upcoming' do
    let!(:user) { create(:user) }

    it 'returns programmed classes with future start_time' do
      past = create(:schedule, start_time: 1.day.ago)
      future = create(:schedule, start_time: 1.day.from_now)
      past_pc = create(:programmed_class, schedule: past, user: user)
      future_pc = create(:programmed_class, schedule: future, user: user)

      expect(described_class.upcoming).to contain_exactly(future_pc)
    end

    it 'orders by start_time ascending' do
      later = create(:schedule, start_time: 2.days.from_now)
      earlier = create(:schedule, start_time: 1.day.from_now)
      later_pc = create(:programmed_class, schedule: later, user: user)
      earlier_pc = create(:programmed_class, schedule: earlier, user: user)

      expect(described_class.upcoming).to eq([earlier_pc, later_pc])
    end
  end
end
