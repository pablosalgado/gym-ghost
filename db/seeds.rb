# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Smoke test fixtures for the Playwright e2e schedule page test (issue #182).
# Triggered when SMOKE_USER_EMAIL is set (CI sets it via docker compose env vars).
if Rails.env.test? || ENV["SMOKE_USER_EMAIL"].present?
  email    = ENV.fetch("SMOKE_USER_EMAIL", "smoke-test@gymghost.test")
  password = ENV.fetch("SMOKE_USER_PASSWORD", "SmokeTest123!")

  # Auth user (Gym Ghost login via /api/v1/auth)
  User.find_or_create_by!(email: email) do |u|
    u.password              = password
    u.password_confirmation = password
  end

  # Gym member (ScheduleController#current_gym_member matches by email)
  GymMember.find_or_create_by!(email: email) do |gm|
    gm.password = password
  end

  # Cities — must match the exact partner strings so auto-select works
  bogota = City.find_or_create_by!(city_name: "BOGOTÁ, D.C.")
  City.find_or_create_by!(city_name: "MEDELLÍN, ANT.")

  # Facilities — must match DEFAULT_FACILITY_NAME in SchedulePage.tsx
  Facility.find_or_create_by!(display_name: "C.C Parque La Colina") do |f|
    f.city        = bogota
    f.external_id = 19_001
    f.name        = "Parque La Colina"
    f.evo_token   = "smoke-evo-token-colina"
  end

  Facility.find_or_create_by!(display_name: "Oviedo") do |f|
    f.city        = City.find_by!(city_name: "MEDELLÍN, ANT.")
    f.external_id = 19_002
    f.name        = "Oviedo"
    f.evo_token   = "smoke-evo-token-oviedo"
  end
end

# Initial admin User for first deployment / initialization (issue #241).
# Triggered when INITIAL_ADMIN_EMAIL is set (provide via .env or compose env).
# Keeps credentials out of source; idempotent via find_or_create_by! (uses
# User's uniqueness validation on email and has_secure_password hashing).
if ENV["INITIAL_ADMIN_EMAIL"].present?
  email    = ENV.fetch("INITIAL_ADMIN_EMAIL")
  password = ENV.fetch("INITIAL_ADMIN_PASSWORD")

  User.find_or_create_by!(email: email) do |u|
    u.password              = password
    u.password_confirmation = password
  end
end
