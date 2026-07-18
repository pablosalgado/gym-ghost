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

  it 'requires a password on create' do
    gym_member = build(:gym_member, password: nil, password_confirmation: nil)

    expect(gym_member).not_to be_valid
    expect(gym_member.errors[:password]).to include("can't be blank")
  end

  it 'authenticates with the correct password' do
    gym_member = create(:gym_member, password: 'Password123!', password_confirmation: 'Password123!')

    expect(gym_member.authenticate('Password123!')).to eq(gym_member)
    expect(gym_member.authenticate('wrong-password')).to be(false)
  end

  it 'has many partner_tokens with dependent destroy' do
    gym_member = create(:gym_member)
    create(:partner_token, gym_member: gym_member)

    expect(gym_member.partner_tokens.count).to eq(1)

    gym_member.destroy

    expect(PartnerToken.where(gym_member_id: gym_member.id).count).to eq(0)
  end
end
