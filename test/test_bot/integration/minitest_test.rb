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

    test '1: seeds and fixtures loaded' do
      assert_normal
    end

    test '2: activerecord can create a user' do
      create_user!
      assert_equal (original_users_count + 1), User.count
    end

    test '3: test database is back to normal' do
      assert_normal
    end

    test '4: capybara can create a user' do
      user = sign_up()
      assert user.kind_of?(User)

      assert_equal (original_users_count + 1), User.count
      assert_signed_in
    end

    test '5: test database is back to normal' do
      assert_normal
    end

    test '6: capybara session has been reset after manual sign up' do
      assert_signed_out
      create_user!
      sign_in(email)
      assert_signed_in
    end

    test '7: test database is back to normal' do
      assert_normal
    end

    test '8: capybara session has been reset after warden login_as' do
      assert_signed_out
    end

    test '9: test database is back to normal' do
      assert_normal
    end

    private

    def assert_normal
      visit root_path
      assert_equal page.status_code, 200
      assert_equal original_users_count, User.count
    end

    def assert_signed_in
      visit new_user_session_path
      assert_content I18n.t('devise.failure.already_authenticated')
      refute page.has_selector?('form#new_user')
    end

    def assert_signed_out
      visit new_user_session_path
      refute_content I18n.t('devise.failure.already_authenticated')
      assert page.has_selector?('form#new_user')
    end

  end
end
