require 'rails_helper'

RSpec.describe ClassType, type: :model do
  subject(:class_type) { build(:class_type) }

  describe 'validations' do
    it { should validate_presence_of(:name) }

    describe ':name' do
      context 'when 3 characters long' do
        it 'is valid' do
          class_type.name = 'A' * 3

          expect(class_type).to be_valid
        end
      end

      context 'when 50 characters long' do
        it 'is valid' do
          class_type.name = 'A' * 50

          expect(class_type).to be_valid
        end
      end

      context 'when blank' do
        it 'is invalid' do
          class_type.name = ''

          expect(class_type).to be_invalid
          expect(class_type.errors[:name]).to include("can't be blank")
        end
      end

      context 'when 2 characters long' do
        it 'is invalid' do
          class_type.name = 'A' * 2

          expect(class_type).to be_invalid
          expect(class_type.errors[:name]).to include("is too short (minimum is 3 characters)")
        end
      end

      context 'when 51 characters long' do
        it 'is invalid' do
          class_type.name = 'A' * 51

          expect(class_type).to be_invalid
          expect(class_type.errors[:name]).to include("is too long (maximum is 50 characters)")
        end
      end
    end

    describe ':duration' do
      it { should validate_presence_of(:duration) }

      context 'when duration is in range' do
        it 'is valid' do
          class_type.duration = 60

          expect(class_type).to be_valid
        end
      end

      context 'when less than zero' do
        it 'is invalid' do
          class_type.duration = -1

          expect(class_type).to be_invalid
          expect(class_type.errors[:duration]).to include("must be greater than or equal to 0")
        end
      end

      context 'when greater than sixty' do
        it 'is invalid' do
          class_type.duration = 61

          expect(class_type).to be_invalid
          expect(class_type.errors[:duration]).to include("must be less than or equal to 60")
        end
      end
    end
  end
end
