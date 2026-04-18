class CreateFacilities < ActiveRecord::Migration[8.1]
  def change
    create_table :facilities do |t|
      t.string :name, null: false
      t.references :city, null: false, foreign_key: true

      t.check_constraint "length(name) >=3 and length(name) <= 50"

      t.timestamps
    end
  end
end
