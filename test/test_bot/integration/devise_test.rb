require 'test_helper'

if defined?(Devise) && defined?(User)
  module TestBot
    class DeviseTest < ActionDispatch::IntegrationTest
      let(:email) { 'unique@testbot.com'}
      let(:password) { '!Password123' }
      let(:create_user!) { User.new(email: email, password: password, password_confirmation: password).save(validate: false) }

      test 'sign up' do
        visit new_user_registration_path

        within('form#new_user') do
          fill_form(email: email, password: password, password_confirmation: password)
          submit_form
        end

        assert_equal page.status_code, 200
        assert_content I18n.t('devise.registrations.signed_up')
        assert User.find_by_email(email).present?
      end

      test 'sign in' do
        create_user!
        visit new_user_session_path

        within('form#new_user') do
          fill_form(email: email, password: password)
          submit_form
        end

        assert_equal 200, page.status_code
        assert_content I18n.t('devise.sessions.signed_in')
        assert_equal 1, User.find_by_email(email).sign_in_count
      end

      test 'invalid sign in' do
        create_user!
        visit new_user_session_path

        within('form#new_user') do
          fill_form(email: email, password: 'not-correct-password')
          submit_form
        end

        assert_equal 200, page.status_code
        assert_content I18n.t('devise.failure.invalid', authentication_keys: Devise.authentication_keys.join(', '))
      end
    end
  end
end
