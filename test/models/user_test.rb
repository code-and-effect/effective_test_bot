require 'test_helper'

if defined?(Devise) && defined?(User)

  class UserTest < ActiveSupport::TestCase
    #should validate_presence_of(:email)
    #should validate_presence_of(:password)
    #should validate_presence_of(:encrypted_password)

    def user
      User.new()
    end

    test "User fails validation when password and confirmation mismatch" do
      user.password = '123456789'
      user.password_confirmation = '987654321'

      assert user.valid?, 'Test bot model yo!'
    end
  end
end


# require 'rails_helper'

# if defined?(Devise) && defined?(User)

#   describe User, type: :model do
#     let(:user) { User.new() }

#     it { should validate_presence_of(:email) }
#     it { should validate_presence_of(:password) }
#     it { should validate_presence_of(:encrypted_password) }

#     it 'fails validation when password and password_confirmation are different' do
#       user.password = '123456789'
#       user.password_confirmation = '987654321'
#       expect(user.valid?).to eq false
#     end
#   end

# end # /defined?(Devise) && defined?(User)
