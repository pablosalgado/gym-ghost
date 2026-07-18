# frozen_string_literal: true

key = Rails.application.credentials.attr_encrypted_key || ENV["ATTR_ENCRYPTED_KEY"]

if key.nil? && Rails.env.production?
  raise "ATTR_ENCRYPTED_KEY must be set in credentials or ENV for production"
end

ENV["ATTR_ENCRYPTED_KEY"] = key if key
