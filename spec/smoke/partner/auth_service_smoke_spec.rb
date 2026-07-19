require "rails_helper"

RSpec.describe Partner::AuthService, smoke: true do
  before do
    skip "Set PARTNER_API_BASE_URL, PARTNER_TEST_MEMBER_EMAIL, and PARTNER_TEST_MEMBER_PASSWORD to run smoke tests" unless
      ENV["PARTNER_API_BASE_URL"].present? &&
      ENV["PARTNER_TEST_MEMBER_EMAIL"].present? &&
      ENV["PARTNER_TEST_MEMBER_PASSWORD"].present?
  end
  # Use real credentials from environment
  let(:gym_member) { create(:gym_member, email: ENV["PARTNER_TEST_MEMBER_EMAIL"], password: ENV["PARTNER_TEST_MEMBER_PASSWORD"]) }
  let(:password) { ENV["PARTNER_TEST_MEMBER_PASSWORD"] }

  subject(:service) { described_class.new(gym_member:, password:) }

  describe "#login with real partner API" do
    it "creates a PartnerToken with real API response" do
      token = service.login

      # Assert token is persisted
      expect(token).to be_persisted

      # Assert token has required attributes
      expect(token.access_token).to be_present
      expect(token.refresh_token).to be_present
      expect(token.token_expires_at).to be_present
      expect(token.token_expires_at).to be > Time.current

      # Assert token belongs to the correct gym member
      expect(token.gym_member).to eq(gym_member)
    end

    it "raises Partner::AuthenticationError on invalid credentials" do
      # Create a gym member with wrong password
      wrong_password_member = create(:gym_member, email: "wrong@example.com", password: "WrongPassword123!")
      wrong_service = described_class.new(gym_member: wrong_password_member, password: "WrongPassword123!")

      # This should raise AuthenticationError, not be rescued and skipped
      expect { wrong_service.login }.to raise_error(Partner::AuthenticationError)
    end
  end
end
