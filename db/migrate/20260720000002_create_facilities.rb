class CreateFacilities < ActiveRecord::Migration[8.1]
  def change
    create_table :facilities do |t|
      t.integer :external_id, null: false
      t.string :name
      t.string :evo_token
      t.string :display_name
      t.references :city, null: false, foreign_key: true

      t.timestamps
    end

    add_index :facilities, :external_id, unique: true
  end
end
