require 'test_helper'

module TestBot
  class EnvironmentTest < ActionDispatch::IntegrationTest
    @@original_users_count = User.count
    let(:original_users_count) { @@original_users_count }

    def self.test_order
      :alpha
    end

    test '01: can visit root_path' do
      visit root_path
      assert_page_status
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

    test '03: at least one user is present' do
      assert (User.count > 0), 'please fixture or seed at least 1 user for effective_test_bot to function'
    end

    test '04: activerecord can save a resource' do
      User.new(email: 'unique@testbot.com', password: '!Password123', password_confirmation: '!Password123').save(validate: false)
      assert_equal (original_users_count + 1), User.count
    end

    test '05: database has rolled back' do
      assert_equal original_users_count, User.count, 'the activerecord resource created in a previous test is still present'
    end

    test '06: capybara can sign_in' do
      sign_in(User.first)
      assert_signed_in
    end

    test '07: capybara session has reset' do
      assert_signed_out
    end

    test '08: capybara can execute javascript' do
      visit root_path
      assert_capybara_can_execute_javascript
    end

    test '09: jquery is present' do
      visit root_path
      assert_jquery_present
    end

    test '10: rails jquery_ujs is present' do
      visit root_path
      assert_jquery_ujs_present
    end

  end
end
