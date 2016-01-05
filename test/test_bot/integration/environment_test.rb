require 'test_helper'

module TestBot
  class EnvironmentTest < ActionDispatch::IntegrationTest
    @@original_users_count = User.count
    let(:original_users_count) { @@original_users_count }

    let(:email) { 'unique@testbot.com' }
    let(:password) { '!Password123' }
    let(:username) { 'test_bot_user' }

    def self.test_order
      :alpha
    end

    test '01: seeds and fixtures loaded' do
      assert_environment_normal
    end

    test '02: all fixtures and seeds valid' do
      tables = ActiveRecord::Base.connection.tables

      ActiveRecord::Base.descendants.each do |model|
        next unless (model.respond_to?(:table_name) && tables.include?(model.table_name))

        (model.unscoped.all rescue []).each do |resource|
          assert resource.valid?, "fixture or seed data is invalid (#{model.to_s} id=#{resource.id} #{resource.errors.full_messages.join(', ')})"
        end
      end
    end

    # I could remove this if sign_in checks for and creates a user with devise or not
    test '03: at least one user is seeded' do
      assert (User.count > 0), 'please create at least 1 seed or fixture user for effective_test_bot to function'
    end

    test '04: activerecord can create a user' do
      create_user!
      assert_equal (original_users_count + 1), User.count
    end

    test '05: test database has reset' do
      assert_environment_normal
    end

    test '06: capybara can execute javascript' do
      visit root_path
      assert_capybara_can_execute_javascript
    end

    test '07: jquery is present' do
      visit root_path
      assert_jquery_present
    end

    test '08: rails jquery_ujs is present' do
      visit root_path
      assert_jquery_ujs_present
    end

    test '09: capybara can sign up a user' do
      user = sign_up()
      assert user.kind_of?(User), "Expected to create a new user after submitting sign up form at #{new_user_registration_path}"

      assert_equal (original_users_count + 1), User.count
      assert_signed_in
    end

    test '10: database and session have reset' do
      assert_signed_out
      assert_environment_normal
    end

    test '11: capybara can login_as via warden test helper' do
      sign_in(User.first || create_user!)
      assert_signed_in
    end

    test '12: database and session have reset' do
      assert_signed_out
      assert_environment_normal
    end

    test '13: capybara can sign in manually' do
      user = create_user!
      sign_in_manually(user, password)
      assert_signed_in
    end

    test '14: database and session have reset' do
      assert_signed_out
      assert_environment_normal
    end

    private

    # This is all about seeing if the cookies, session, and database are rolling back properly in between tests
    def assert_environment_normal
      visit root_path
      assert_page_status
      assert_equal original_users_count, User.count, 'Expected User.count to be back to original'
      assert assigns[:current_user].blank?, 'Expected current_user to be blank'
    end

    def create_user!
      user = User.new(email: email, password: password, password_confirmation: password)
      user.username = username if user.respond_to?('username=')
      user.login = username if user.respond_to?('login=')

      user.valid? ? user.save : user.save(validate: false)

      user
    end

  end
end
