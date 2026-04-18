class CreateSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :schedules do |t|
      t.references :facility, null: false, foreign_key: true
      t.references :class_type, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time :start_time, null: false
      t.boolean :is_holiday_schedule, default: false, null: false

      t.check_constraint "day_of_week >= 0 and day_of_week <= 6"

      t.timestamps
    end
  end
end
