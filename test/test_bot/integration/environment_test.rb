require 'test_helper'

module TestBot
  class EnvironmentTest < ActionDispatch::IntegrationTest
    @@original_users_count = User.count
    let(:original_users_count) { @@original_users_count }

    let(:email) { 'unique@testbot.com' }
    let(:password) { '!Password123' }
    let(:create_user!) { User.new(email: email, password: password, password_confirmation: password).save(validate: false) }

    def self.test_order
      :alpha
    end

    test '01: seeds and fixtures loaded' do
      assert_normal
    end

    test '02: all fixtures and seeds valid' do
      ActiveRecord::Base.descendants.each do |model|
        begin
          (model.unscoped.all rescue []).each do |resource|
            assert resource.valid?, "fixture or seed data is invalid (#{model.to_s} id=#{resource.id} #{resource.errors.full_messages.join(', ')})"
          end
        rescue ActiveRecord::StatementInvalid
          ; # Not entirely sure why I'm getting this error
        end
      end
    end

    # I could remove this if sign_in checks for and creates a user with devise or not
    test '03: at least one user is seeded' do
      assert (User.all.count > 0), 'please create at least 1 seed or fixture user for effective_test_bot to function'
    end

    test '04: activerecord can create a user' do
      create_user!
      assert_equal (original_users_count + 1), User.count
    end

    test '05: test database has reset' do
      assert_normal
    end

    test '06: capybara can sign up a user' do
      user = sign_up()
      assert user.kind_of?(User)

      assert_equal (original_users_count + 1), User.count
      assert_signed_in
    end

    test '07: database and session have reset' do
      assert_signed_out
      assert_normal
    end

    test '08: capybara can login_as via warden test helper' do
      create_user!
      sign_in(email)
      assert_signed_in
    end

    test '09: database and session have reset' do
      assert_signed_out
      assert_normal
    end

    test '10: capybara can sign in manually' do
      create_user!
      sign_in_manually(email, password)
      assert_signed_in
    end

    test '11: database and session have reset' do
      assert_signed_out
      assert_normal
    end

    private

    def assert_normal
      visit root_path
      assert_page_status
      assert_equal original_users_count, User.count, 'Epected User.count to be back to original'
      assert assigns[:current_user].blank?, 'Expected current_user to be blank'
    end

  end
end
