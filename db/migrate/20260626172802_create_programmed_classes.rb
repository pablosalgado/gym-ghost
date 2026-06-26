class CreateProgrammedClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :programmed_classes do |t|
      t.references :schedule, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "programmed"

      t.timestamps

      t.index %i[schedule_id user_id], unique: true
    end
  end
end
