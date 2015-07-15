require 'test_helper'

if defined?(Devise) && defined?(User)
  module TestBot
    class UserTest < ActiveSupport::TestCase
      let(:user) { User.new() }

      # These are mostly here as an example of using shoulda
      # I don't find that I use the gem, but I see it's value
      should validate_presence_of(:email)
      should validate_presence_of(:password)
      should validate_presence_of(:encrypted_password)

      test "user invalid when password and confirmation mismatch" do
        user.password = '123456789'
        user.password_confirmation = '987654321'

        refute user.valid?, 'user should be invalid with mismatched passwords'
      end
    end
  end
end
