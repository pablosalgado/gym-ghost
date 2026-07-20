require 'rails_helper'

RSpec.describe City, type: :model do
  it 'is valid with a valid city_name' do
    expect(build(:city)).to be_valid
  end

  it 'is persisted after create' do
    city = create(:city)

    expect(city).to be_persisted
    expect(city.city_name).to be_present
  end

  it 'requires a city_name' do
    city = build(:city, city_name: nil)

    expect(city).not_to be_valid
    expect(city.errors[:city_name]).to include("can't be blank")
  end

  it 'requires a unique city_name' do
    create(:city, city_name: 'Bogota')
    city = build(:city, city_name: 'Bogota')

    expect(city).not_to be_valid
    expect(city.errors[:city_name]).to include('has already been taken')
  end

  it 'has many facilities' do
    expect(City.reflect_on_association(:facilities).macro).to eq(:has_many)
  end
end
