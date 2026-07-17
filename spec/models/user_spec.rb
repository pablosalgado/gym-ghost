require 'rails_helper'

RSpec.describe User, type: :model do
  it 'is valid with a valid email and password' do
    expect(build(:user)).to be_valid
  end

  it 'requires an email' do
    user = build(:user, email: nil)

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end

  it 'requires a unique email case-insensitively' do
    create(:user, email: 'duplicate@example.com')
    user = build(:user, email: 'DUPLICATE@example.com')

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include('has already been taken')
  end

  it 'requires a valid email format' do
    user = build(:user, email: 'invalid-email')

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include('is invalid')
  end

  it 'requires a password on create' do
    user = build(:user, password: nil, password_confirmation: nil)

    expect(user).not_to be_valid
    expect(user.errors[:password]).to include("can't be blank")
  end

  it 'authenticates with the correct password' do
    user = create(:user, password: 'Password123!', password_confirmation: 'Password123!')

    expect(user.authenticate('Password123!')).to eq(user)
    expect(user.authenticate('wrong-password')).to be(false)
  end
end
