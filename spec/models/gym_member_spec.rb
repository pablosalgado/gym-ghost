require 'rails_helper'

RSpec.describe GymMember, type: :model do
  it 'is valid with a valid email and password' do
    expect(build(:gym_member)).to be_valid
  end

  it 'requires an email' do
    gym_member = build(:gym_member, email: nil)

    expect(gym_member).not_to be_valid
    expect(gym_member.errors[:email]).to include("can't be blank")
  end

  it 'requires a unique email case-insensitively' do
    create(:gym_member, email: 'duplicate@example.com')
    gym_member = build(:gym_member, email: 'DUPLICATE@example.com')

    expect(gym_member).not_to be_valid
    expect(gym_member.errors[:email]).to include('has already been taken')
  end

  it 'requires a valid email format' do
    gym_member = build(:gym_member, email: 'invalid-email')

    expect(gym_member).not_to be_valid
    expect(gym_member.errors[:email]).to include('is invalid')
  end

  it 'requires a password' do
    gym_member = build(:gym_member, password: nil)

    expect(gym_member).not_to be_valid
    expect(gym_member.errors[:password]).to include("can't be blank")
  end

  it 'has many partner_tokens with dependent destroy' do
    gym_member = create(:gym_member)
    create(:partner_token, gym_member: gym_member)

    expect(gym_member.partner_tokens.count).to eq(1)

    gym_member.destroy

    expect(PartnerToken.where(gym_member_id: gym_member.id).count).to eq(0)
  end

  describe 'password encryption' do
    it 'encrypts the password at rest and decrypts on read' do
      gym_member = create(:gym_member, password: 'plaintext-partner-secret')

      expect(gym_member.encrypted_password).not_to eq('plaintext-partner-secret')
      expect(gym_member.encrypted_password).to be_present
      expect(gym_member.encrypted_password_iv).to be_present
      expect(gym_member.password).to eq('plaintext-partner-secret')
    end

    it 'does not store the password in a recoverable bcrypt digest' do
      expect(GymMember.column_names).not_to include('password_digest')
    end
  end
end
