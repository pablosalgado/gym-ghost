class ChangeScheduleStartTimeType < ActiveRecord::Migration[8.1]
  def change
    change_column :schedules, :start_time, :datetime, null: false
  end
end
