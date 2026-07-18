# frozen_string_literal: true

class PartnerToken < ApplicationRecord
  belongs_to :gym_member

  attr_encrypted :access_token, key: ENV.fetch("ATTR_ENCRYPTED_KEY")
  attr_encrypted :refresh_token, key: ENV.fetch("ATTR_ENCRYPTED_KEY")

  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :token_expires_at, presence: true

  scope :valid_tokens, -> { where("token_expires_at > ?", Time.current) }
end
