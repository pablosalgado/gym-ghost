class CreateGymMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :gym_members do |t|
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :gym_members, :email, unique: true
  end
end
