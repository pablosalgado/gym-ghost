require 'rails_helper'

RSpec.describe Schedule, type: :model do
  subject(:schedule) { build(:schedule) }

  describe 'associations' do
    it { should belong_to(:facility) }
    it { should belong_to(:class_type) }
  end

  describe 'validations' do
    it { should validate_presence_of(:day_of_week) }
    it { should validate_presence_of(:start_time) }

    describe ':day_of_week' do
      context 'when an unknown value' do
        it 'raises ArgumentError' do
          expect { schedule.day_of_week = 'foo' }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError for out-of-range integer' do
          expect { schedule.day_of_week = -1 }.to raise_error(ArgumentError)
        end
      end

      context 'when a valid day' do
        it 'is valid' do
          schedule.day_of_week = :monday

          expect(schedule).to be_valid
        end
      end
    end
  end
end
