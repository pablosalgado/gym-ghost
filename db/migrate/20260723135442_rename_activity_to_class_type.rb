class RenameActivityToClassType < ActiveRecord::Migration[8.1]
  def change
    rename_table :activities, :class_types
    rename_column :schedule_entries, :activity_id, :class_type_id
    rename_index :schedule_entries,
                 "index_schedule_entries_on_activity_id",
                 "index_schedule_entries_on_class_type_id"
    rename_index :schedule_entries,
                 "index_schedule_entries_on_facility_id_and_activity_id",
                 "index_schedule_entries_on_facility_id_and_class_type_id"
  end
end
