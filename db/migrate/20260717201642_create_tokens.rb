class CreateTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :digest, null: false

      t.timestamps
    end

    add_index :tokens, :digest, unique: true
  end
end
