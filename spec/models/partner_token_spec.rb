require 'rails_helper'

RSpec.describe PartnerToken, type: :model do
  it 'is valid with a gym_member, access_token, refresh_token, and token_expires_at' do
    expect(build(:partner_token)).to be_valid
  end

  it 'requires an access_token' do
    partner_token = build(:partner_token, access_token: nil)

    expect(partner_token).not_to be_valid
    expect(partner_token.errors[:access_token]).to include("can't be blank")
  end

  it 'requires a refresh_token' do
    partner_token = build(:partner_token, refresh_token: nil)

    expect(partner_token).not_to be_valid
    expect(partner_token.errors[:refresh_token]).to include("can't be blank")
  end

  it 'requires a token_expires_at' do
    partner_token = build(:partner_token, token_expires_at: nil)

    expect(partner_token).not_to be_valid
    expect(partner_token.errors[:token_expires_at]).to include("can't be blank")
  end

  it 'belongs to a gym_member' do
    partner_token = build(:partner_token, gym_member: nil)

    expect(partner_token).not_to be_valid
    expect(partner_token.errors[:gym_member]).to include('must exist')
  end

  describe '.valid_tokens' do
    it 'returns non-expired tokens' do
      valid_token = create(:partner_token, token_expires_at: 1.hour.from_now)

      expect(described_class.valid_tokens).to include(valid_token)
    end

    it 'excludes expired tokens' do
      expired_token = create(:partner_token, token_expires_at: 1.hour.ago)

      expect(described_class.valid_tokens).not_to include(expired_token)
    end
  end

  describe 'token encryption' do
    it 'encrypts access_token and refresh_token at rest' do
      partner_token = create(:partner_token, access_token: 'secret-access', refresh_token: 'secret-refresh')

      expect(partner_token.encrypted_access_token).not_to eq('secret-access')
      expect(partner_token.encrypted_refresh_token).not_to eq('secret-refresh')
      expect(partner_token.access_token).to eq('secret-access')
      expect(partner_token.refresh_token).to eq('secret-refresh')
    end
  end
end
