class User < ApplicationRecord
  has_secure_password
  has_many :tokens, dependent: :destroy

  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, on: :create
end
