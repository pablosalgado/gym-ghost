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

ActiveRecord::Schema[8.1].define(version: 2026_04_17_171025) do
  create_table "cities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "length(name) >= 3 and length(name) <= 50"
  end

  create_table "class_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "duration >= 0 and duration <= 60"
    t.check_constraint "length(name) >= 3 and length(name) <= 50"
  end

  create_table "facilities", force: :cascade do |t|
    t.integer "city_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_facilities_on_city_id"
    t.check_constraint "length(name) >=3 and length(name) <= 50"
  end

  create_table "schedules", force: :cascade do |t|
    t.integer "class_type_id", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.integer "facility_id", null: false
    t.boolean "is_holiday_schedule", default: false
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["class_type_id"], name: "index_schedules_on_class_type_id"
    t.index ["facility_id"], name: "index_schedules_on_facility_id"
    t.check_constraint "day_of_week >= 0 and day_of_week <= 6"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "facilities", "cities"
  add_foreign_key "schedules", "class_types"
  add_foreign_key "schedules", "facilities"
  add_foreign_key "sessions", "users"
end
