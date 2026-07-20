require 'rails_helper'

RSpec.describe Activity, type: :model do
  it 'is valid with valid attributes' do
    expect(build(:activity)).to be_valid
  end

  it 'is persisted after create' do
    activity = create(:activity)

    expect(activity).to be_persisted
    expect(activity.name).to be_present
  end

  it 'requires a name' do
    activity = build(:activity, name: nil)

    expect(activity).not_to be_valid
    expect(activity.errors[:name]).to include("can't be blank")
  end

  it 'requires a unique name' do
    create(:activity, name: 'Unique Class')
    activity = build(:activity, name: 'Unique Class')

    expect(activity).not_to be_valid
    expect(activity.errors[:name]).to include('has already been taken')
  end



  it 'has many schedule_entries' do
    expect(Activity.reflect_on_association(:schedule_entries).macro).to eq(:has_many)
  end

  it 'destroys associated schedule_entries on destroy' do
    activity = create(:activity)
    create(:schedule_entry, activity:)

    expect { activity.destroy }.to change(ScheduleEntry, :count).by(-1)
  end
end
