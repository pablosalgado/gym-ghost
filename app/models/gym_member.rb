class GymMember < ApplicationRecord
  has_many :partner_tokens, dependent: :destroy

  # Reversibly encrypted plaintext partner credential. Decrypts on read so
  # Partner::AuthService can send it to the downstream login endpoint.
  # Distinct from User#has_secure_password, which authenticates Gym Ghost's
  # own API users with a one-way bcrypt hash.
  attr_encrypted :password, key: ENV.fetch("ATTR_ENCRYPTED_KEY")

  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true
end
