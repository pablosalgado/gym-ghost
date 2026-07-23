require 'rails_helper'

RSpec.describe ScheduleEntry, type: :model do
  it 'is valid with valid attributes' do
    expect(build(:schedule_entry)).to be_valid
  end

  it 'is persisted after create' do
    schedule_entry = create(:schedule_entry)

    expect(schedule_entry).to be_persisted
    expect(schedule_entry.date).to eq(Date.new(2026, 7, 21))
    expect(schedule_entry.start_time).to eq(Time.zone.parse("2026-07-21 07:00:00 UTC"))
  end

  it 'requires a date' do
    schedule_entry = build(:schedule_entry, date: nil)

    expect(schedule_entry).not_to be_valid
    expect(schedule_entry.errors[:date]).to include("can't be blank")
  end

  it 'requires a start_time' do
    schedule_entry = build(:schedule_entry, start_time: nil)

    expect(schedule_entry).not_to be_valid
    expect(schedule_entry.errors[:start_time]).to include("can't be blank")
  end

  it 'belongs to a facility' do
    expect(ScheduleEntry.reflect_on_association(:facility).macro).to eq(:belongs_to)
  end

  it 'belongs to a class_type' do
    expect(ScheduleEntry.reflect_on_association(:class_type).macro).to eq(:belongs_to)
  end

  it 'requires a facility' do
    schedule_entry = build(:schedule_entry, facility: nil)

    expect(schedule_entry).not_to be_valid
    expect(schedule_entry.errors[:facility]).to include("must exist")
  end

  it 'requires a class_type' do
    schedule_entry = build(:schedule_entry, class_type: nil)

    expect(schedule_entry).not_to be_valid
    expect(schedule_entry.errors[:class_type]).to include("must exist")
  end
end
