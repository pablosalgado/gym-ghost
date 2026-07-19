# frozen_string_literal: true

require "partner/auth_service"
require "partner/authentication_error"

namespace :partner do
  namespace :smoke do
    desc "Smoke-test partner authentication end-to-end"
    task auth: :environment do
      # Validate all required env vars early — KeyError is rescued below.
      ENV.fetch("PARTNER_API_BASE_URL")
      ENV.fetch("PARTNER_BRANCH_ID")
      ENV.fetch("PARTNER_BRANCH_CODE")
      test_email = ENV.fetch("PARTNER_TEST_MEMBER_EMAIL")
      test_password = ENV.fetch("PARTNER_TEST_MEMBER_PASSWORD")
      persist = ENV.fetch("PARTNER_SMOKE_PERSIST", "true")

      gym_member = GymMember.find_or_create_by!(email: test_email) do |m|
        m.password = test_password
      end

      dry_run = persist.downcase == "false"

      if dry_run
        ActiveRecord::Base.transaction do
          token = Partner::AuthService.new(gym_member:, password: test_password).login
          puts "PASS (dry-run) — tokens received, transaction rolled back"
          puts "  access_token:  #{token.access_token[0..12]}..."
          puts "  refresh_token: #{token.refresh_token[0..12]}..."
          puts "  token_expires_at: #{token.token_expires_at.utc.iso8601}"
          raise ActiveRecord::Rollback
        end
      else
        gym_member.partner_tokens.delete_all

        token = Partner::AuthService.new(gym_member:, password: test_password).login
        seconds_to_expiry = (token.token_expires_at.utc - Time.current.utc).to_i

        puts "PASS — PartnerToken id=#{token.id}, gym_member_id=#{gym_member.id}, " \
             "token_expires_at=#{token.token_expires_at.utc.iso8601} " \
             "(expires in #{seconds_to_expiry}s)"
      end

      exit 0
    rescue Partner::AuthenticationError => e
      puts "FAIL — #{e.message}"
      exit 1
    rescue KeyError => e
      puts "CONFIG MISSING — #{e.key}"
      exit 2
    rescue => e
      puts "ERROR — #{e.class}: #{e.message}"
      exit 3
    end
  end
end
