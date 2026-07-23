require 'rails_helper'

RSpec.describe ClassType, type: :model do
  it 'is valid with valid attributes' do
    expect(build(:class_type)).to be_valid
  end

  it 'is persisted after create' do
    class_type = create(:class_type)

    expect(class_type).to be_persisted
    expect(class_type.name).to be_present
  end

  it 'requires a name' do
    class_type = build(:class_type, name: nil)

    expect(class_type).not_to be_valid
    expect(class_type.errors[:name]).to include("can't be blank")
  end

  it 'requires a unique name' do
    create(:class_type, name: 'Unique Class')
    class_type = build(:class_type, name: 'Unique Class')

    expect(class_type).not_to be_valid
    expect(class_type.errors[:name]).to include('has already been taken')
  end



  it 'has many schedule_entries' do
    expect(ClassType.reflect_on_association(:schedule_entries).macro).to eq(:has_many)
  end

  it 'destroys associated schedule_entries on destroy' do
    class_type = create(:class_type)
    create(:schedule_entry, class_type:)

    expect { class_type.destroy }.to change(ScheduleEntry, :count).by(-1)
  end
end
