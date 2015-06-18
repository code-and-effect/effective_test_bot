require 'test_helper'

module TestBot
  class MinitestTest < ActionDispatch::IntegrationTest
    @@original_users_count = User.count
    let(:original_users_count) { @@original_users_count }

    let(:email) { 'unique@testbot.com'}
    let(:password) { '!Password123' }
    let(:create_user!) { User.new(email: email, password: password, password_confirmation: password).save(validate: false) }

    def self.test_order
      :alpha
    end

    test 'A: seeds and fixtures loaded' do
      assert_normal
    end

    test 'B: i can use activerecord to create a user' do
      create_user!
      assert_equal (original_users_count + 1), User.count
    end

    test 'C: the test database is back to normal' do
      assert_normal
    end

    test 'D: i can use capybara to create a user' do
      user = sign_up()
      assert user.kind_of?(User)

      assert_equal (original_users_count + 1), User.count
      assert_signed_in
    end

    test 'E: the test database is back to normal' do
      assert_normal
    end

    test 'F: i am in a new capybara session, not currently signed in (after signing up in D)' do
      create_user!
      assert_signed_out
      sign_in(email)
      assert_signed_in
    end

    test 'G: i am still in a new capybara session, not currently signed in' do
      assert_signed_out

      sign_up(email, password) and teardown()
      assert_signed_out

      sign_in_manually(email, password)
      assert_signed_in
    end

    test 'H: i can use the with_user helper' do
      create_user!
      assert_signed_out
      as_user(User.first) { assert_signed_in }
      assert_signed_out
    end

    private

    def assert_normal
      visit root_path
      assert_equal page.status_code, 200
      assert_equal original_users_count, User.count
    end

    def assert_signed_in
      visit new_user_session_path
      assert_content 'You are already signed in. '
      refute page.has_selector?('form#new_user')
    end

    def assert_signed_out
      visit new_user_session_path
      refute_content 'You are already signed in. '
      assert_content 'Log in'
      assert page.has_selector?('form#new_user')
    end

  end
end
