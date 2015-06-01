require 'rails_helper'

if defined?(Devise) && defined?(User)

  describe User, type: :model do
    let(:user) { User.new() }

    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:encrypted_password) }

    it 'fails validation when password and password_confirmation are different' do
      user.password = '123456789'
      user.password_confirmation = '987654321'
      expect(user.valid?).to eq false
    end
  end

end # /defined?(Devise) && defined?(User)
