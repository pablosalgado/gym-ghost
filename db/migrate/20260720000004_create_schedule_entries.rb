class CreateScheduleEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_entries do |t|
      t.references :activity, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true
      t.date :date, null: false
      t.datetime :start_time, null: false

      t.timestamps
    end

    add_index :schedule_entries, [ :facility_id, :activity_id ]
  end
end
