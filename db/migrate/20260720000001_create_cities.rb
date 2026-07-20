class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities do |t|
      t.string :city_name, null: false

      t.timestamps
    end

    add_index :cities, :city_name, unique: true
  end
end
