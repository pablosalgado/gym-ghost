class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :activities, :name, unique: true
  end
end
