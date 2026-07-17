require "digest"

class Token < ApplicationRecord
  belongs_to :user

  validates :digest, presence: true, uniqueness: true

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
