require 'test_helper'

module TestBot
  class DatabaseTest < ActiveSupport::TestCase
    test 'should be 1 user record available' do
      assert_equal 1, User.count
    end

    test 'should be 0 user records available after delete' do
      User.destroy_all
      assert_equal 0, User.count
    end

    test 'should be 2 user records if I create one' do
      assert_equal 1, User.count
      assert User.create(:email => 'someone@somehting.com', :password => '123456789', :password_confirmation => '123456789')

      assert_equal 2, User.count

    end


  end
end
