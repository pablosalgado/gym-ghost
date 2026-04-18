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

      context 'when black' do
        it 'is invalid' do
          class_type.name = ''

          expect(class_type).to be_invalid
          expect(class_type.errors[:name]).to include("can't be blank")
        end
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
        it 'is invalid ' do
          class_type.name = 'A' * 51

          expect(class_type).to be_invalid
          expect(class_type.errors[:name]).to include("is too long (maximum is 50 characters)")
        end
      end
  end
end
