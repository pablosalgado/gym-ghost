require 'rails_helper'

RSpec.describe Token, type: :model do
  it 'is valid with a user and digest' do
    expect(build(:token)).to be_valid
  end

  it 'requires a digest' do
    token = build(:token, digest: nil)

    expect(token).not_to be_valid
    expect(token.errors[:digest]).to include("can't be blank")
  end

  it 'requires a unique digest' do
    digest = Token.digest('raw-token-value')
    create(:token, digest:)
    token = build(:token, digest:)

    expect(token).not_to be_valid
    expect(token.errors[:digest]).to include('has already been taken')
  end

  it 'belongs to a user' do
    token = build(:token, user: nil)

    expect(token).not_to be_valid
    expect(token.errors[:user]).to include('must exist')
  end

  describe '.digest' do
    it 'returns an SHA256 digest for the raw token' do
      expect(described_class.digest('raw-token-value')).to eq(Digest::SHA256.hexdigest('raw-token-value'))
    end
  end
end
