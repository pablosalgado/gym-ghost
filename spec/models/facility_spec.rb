require 'rails_helper'

RSpec.describe Facility, type: :model do
  subject(:facility) { build(:facility) }

  describe 'associations' do
    it { should belong_to(:city) }
    it { should have_many(:schedules).dependent(:destroy) }
  end

  describe 'validations' do
    describe ':city' do
      context 'when null' do
        it 'is invalid' do
          facility.city = nil

          expect(facility).to be_invalid
          expect(facility.errors[:city]).to include("must exist")
        end
      end
    end

    describe ':name'  do
      it { should validate_presence_of(:name) }

      context 'when 3 characters long' do
        it 'is valid' do
          facility.name = 'A' * 3

          expect(facility).to be_valid
        end
      end

      context 'when 50 characters long' do
        it 'is valid' do
          facility.name = 'A' * 50

          expect(facility).to be_valid
        end
      end

      context 'when blank' do
        it 'is invalid' do
          facility.name = ''

          expect(facility).to be_invalid
          expect(facility.errors[:name]).to include("can't be blank")
        end
      end

      context 'when 2 characters long' do
        it 'is invalid' do
          facility.name = 'A' * 2

          expect(facility).to be_invalid
          expect(facility.errors[:name]).to include("is too short (minimum is 3 characters)")
        end
      end
    end

    context 'when 51 characters long' do
      it 'is invalid' do
        facility.name = 'A' * 51

        expect(facility).to be_invalid
        expect(facility.errors[:name]).to include("is too long (maximum is 50 characters)")
      end
    end
  end
end
