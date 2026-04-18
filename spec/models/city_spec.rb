require 'rails_helper'

RSpec.describe City, type: :model do
  subject(:city) { build(:city) }

  describe 'associations' do
    it { should have_many(:facilities).dependent(:destroy) }
  end

  describe 'validations' do
    describe ':name' do
      it { should validate_presence_of(:name) }

      context 'when 3 characters long' do
        it 'is valid' do
          city.name = 'A' * 3

          expect(city).to be_valid
        end
      end

      context 'when 50 characters long' do
        it 'is valid' do
          city.name = 'A' * 50

          expect(city).to be_valid
        end
      end

      context 'when blank' do
        it 'is invalid' do
          city.name = ''

          expect(city).to be_invalid
          expect(city.errors[:name]).to include("can't be blank")
        end
      end

      context 'when 2 characters long' do
        it 'is invalid' do
          city.name = 'A' * 2

          expect(city).to be_invalid
          expect(city.errors[:name]).to include('is too short (minimum is 3 characters)')
        end
      end

      context 'when 51 characters long' do
        it 'is invalid' do
          city.name = 'A' * 51

          expect(city).to be_invalid
          expect(city.errors[:name]).to include('is too long (maximum is 50 characters)')
        end
      end
    end
  end

  describe 'dependent destroy' do
    it 'destroys associated facilities when the city is destroyed' do
      city = create(:city)
      facility = create(:facility, city: city)

      expect { city.destroy }.to change(Facility, :count).by(-1)
      expect { facility.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
