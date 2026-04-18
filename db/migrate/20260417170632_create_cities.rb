class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities do |t|
      t.string :name, null: false

      t.check_constraint "length(name) >= 3 and length(name) <= 50"

      t.timestamps
    end
  end
end
