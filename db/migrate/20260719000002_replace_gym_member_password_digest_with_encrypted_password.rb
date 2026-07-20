# frozen_string_literal: true

# Replaces the bcrypt-backed password column on `gym_members` with a
# reversibly encrypted one. `GymMember` is not an authenticated user of
# Gym Ghost — it stores a partner API email/password combo that must be
# recoverable to send to the partner login endpoint. `password_digest`
# (bcrypt) is a one-way hash and cannot serve that purpose, so it is
# removed and a single attr_encrypted `password` attribute takes its place.
#
# Production impact of dropping `password_digest`: existing bcrypt hashes
# are lost forever and cannot be reconstructed. Reversing this migration
# would re-add the column as nullable, leaving existing rows without a
# usable credential — a one-way migration. Acceptable here because the
# `User` model is the authenticated Gym Ghost account; `GymMember`
# credentials are partner-only and were never authenticated via bcrypt.
class ReplaceGymMemberPasswordDigestWithEncryptedPassword < ActiveRecord::Migration[8.1]
  def up
    remove_column :gym_members, :password_digest
    add_column :gym_members, :encrypted_password, :string
    add_column :gym_members, :encrypted_password_iv, :string
    change_column_null :gym_members, :encrypted_password, false
    change_column_null :gym_members, :encrypted_password_iv, false
  end

  def down
    change_column_null :gym_members, :encrypted_password_iv, true
    change_column_null :gym_members, :encrypted_password, true
    remove_column :gym_members, :encrypted_password_iv
    remove_column :gym_members, :encrypted_password
    add_column :gym_members, :password_digest, :string, null: false
  end
end
