class CreateClassTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :class_types do |t|
      t.string :name, null: false
      t.integer :duration, null: false

      t.check_constraint "length(name) >= 3 and length(name) <= 50"
      t.check_constraint "duration >= 0 and duration <= 60"

      t.timestamps
    end
  end
end
