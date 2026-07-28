class AddIndexToScheduleEntry < ActiveRecord::Migration[8.1]
  def change
    add_index :schedule_entries, [ :facility_id, :class_type_id, :start_time ], unique: true
  end
end
