# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_23_135442) do
  create_table "cities", force: :cascade do |t|
    t.string "city_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city_name"], name: "index_cities_on_city_name", unique: true
  end

  create_table "class_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_class_types_on_name", unique: true
  end

  create_table "facilities", force: :cascade do |t|
    t.integer "city_id", null: false
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "evo_token"
    t.integer "external_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_facilities_on_city_id"
    t.index ["external_id"], name: "index_facilities_on_external_id", unique: true
  end

  create_table "gym_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "encrypted_password_iv", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_gym_members_on_email", unique: true
  end

  create_table "partner_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_access_token", null: false
    t.string "encrypted_access_token_iv", null: false
    t.string "encrypted_refresh_token", null: false
    t.string "encrypted_refresh_token_iv", null: false
    t.integer "gym_member_id", null: false
    t.datetime "token_expires_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gym_member_id"], name: "index_partner_tokens_on_gym_member_id"
  end

  create_table "schedule_entries", force: :cascade do |t|
    t.integer "class_type_id", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "facility_id", null: false
    t.datetime "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["class_type_id"], name: "index_schedule_entries_on_class_type_id"
    t.index ["facility_id", "class_type_id"], name: "index_schedule_entries_on_facility_id_and_class_type_id"
    t.index ["facility_id"], name: "index_schedule_entries_on_facility_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "digest", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["digest"], name: "index_tokens_on_digest", unique: true
    t.index ["user_id"], name: "index_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "facilities", "cities"
  add_foreign_key "partner_tokens", "gym_members"
  add_foreign_key "schedule_entries", "class_types"
  add_foreign_key "schedule_entries", "facilities"
  add_foreign_key "tokens", "users"
end
