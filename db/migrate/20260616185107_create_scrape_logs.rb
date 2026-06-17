class CreateScrapeLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :scrape_logs do |t|
      t.string :facility, null: false
      t.date :date, null: false
      t.string :status, null: false, default: "completed"
      t.text :error_message

      t.timestamps
    end

    add_index :scrape_logs, %i[facility date], unique: true
  end
end
