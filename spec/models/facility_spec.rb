require 'rails_helper'

RSpec.describe Facility, type: :model do
  it 'is valid with all attributes' do
    expect(build(:facility)).to be_valid
  end

  it 'is persisted after create' do
    facility = create(:facility)

    expect(facility).to be_persisted
    expect(facility.external_id).to be_present
    expect(facility.name).to eq('Branch Gym')
    expect(facility.evo_token).to eq('evo-token-abc')
    expect(facility.display_name).to eq('Branch Display')
  end

  it 'requires an external_id' do
    facility = build(:facility, external_id: nil)

    expect(facility).not_to be_valid
    expect(facility.errors[:external_id]).to include("can't be blank")
  end

  it 'requires a unique external_id' do
    create(:facility, external_id: 42)
    facility = build(:facility, external_id: 42)

    expect(facility).not_to be_valid
    expect(facility.errors[:external_id]).to include('has already been taken')
  end

  it 'requires a city' do
    facility = build(:facility, city: nil)

    expect(facility).not_to be_valid
    expect(facility.errors[:city]).to include("must exist")
  end

  it 'belongs to a city' do
    expect(Facility.reflect_on_association(:city).macro).to eq(:belongs_to)
  end
end
