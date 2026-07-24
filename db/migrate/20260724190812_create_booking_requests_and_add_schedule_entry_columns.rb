class CreateBookingRequestsAndAddScheduleEntryColumns < ActiveRecord::Migration[8.1]
  def change
    change_table :schedule_entries do |t|
      t.string :partner_activity_id
      t.integer :activ_config_id
    end

    create_table :booking_requests do |t|
      t.references :gym_member, null: false, foreign_key: true
      t.references :schedule_entry, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :booking_window_opens_at, null: false
      t.string :partner_confirmation_id
      t.string :error_message

      t.timestamps
    end

    add_index :booking_requests, [ :gym_member_id, :schedule_entry_id ],
      unique: true,
      where: "status IN (0, 1)",
      name: "idx_booking_requests_on_member_schedule_unique_active"
  end
end
