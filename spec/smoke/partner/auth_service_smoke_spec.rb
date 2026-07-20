require "rails_helper"

RSpec.describe Partner::AuthService, smoke: true do
  before do
    skip "Set PARTNER_API_BASE_URL, all TEST_PARTNER_AUTH_* vars (including " \
         "REFERER and ORIGIN) to run smoke tests" unless
      ENV["PARTNER_API_BASE_URL"].present? &&
      ENV["TEST_PARTNER_AUTH_EMAIL"].present? &&
      ENV["TEST_PARTNER_AUTH_PASSWORD"].present? &&
      ENV["TEST_PARTNER_AUTH_PARTNER_NAME"].present? &&
      ENV["TEST_PARTNER_AUTH_BRANCH_ID"].present? &&
      ENV["TEST_PARTNER_AUTH_BRANCH_NAME"].present? &&
      ENV["TEST_PARTNER_AUTH_TOKEN_BRANCH"].present? &&
      ENV["TEST_PARTNER_AUTH_COUNTRY_CODE"].present? &&
      ENV["PARTNER_AUTH_REFERER"].present? &&
      ENV["PARTNER_AUTH_ORIGIN"].present?
  end
  # Use real credentials from environment
  let(:gym_member) { create(:gym_member, email: ENV["TEST_PARTNER_AUTH_EMAIL"], password: ENV["TEST_PARTNER_AUTH_PASSWORD"]) }

  subject(:service) { described_class.new(gym_member:) }

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
      wrong_password_member = create(:gym_member, email: "wrong@example.com", password: "WrongPassword123!")
      wrong_service = described_class.new(gym_member: wrong_password_member)

      # This should raise AuthenticationError, not be rescued and skipped
      expect { wrong_service.login }.to raise_error(Partner::AuthenticationError)
    end
  end
end
