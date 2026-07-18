class CreatePartnerTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :partner_tokens do |t|
      t.references :gym_member, null: false, foreign_key: true
      t.string :encrypted_access_token, null: false
      t.string :encrypted_access_token_iv, null: false
      t.string :encrypted_refresh_token, null: false
      t.string :encrypted_refresh_token_iv, null: false
      t.datetime :token_expires_at, null: false

      t.timestamps
    end
  end
end
