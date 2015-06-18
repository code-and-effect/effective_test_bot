require 'test_helper'

if defined?(Devise) && defined?(User)
  module TestBot
    class SignUpTest < ActionDispatch::IntegrationTest
      let(:user) { users(:normal) }

      test 'valid sign up' do
        visit new_user_registration_path

        email = Faker::Internet.email
        password = Faker::Internet.password

        within('form#new_user') do
          fill_form(:email => email, :password => password, :password_confirmation => password)
          submit_form
        end

        assert_equal page.status_code, 200
        assert_content I18n.t('devise.registrations.signed_up')
        assert User.find_by_email(email).present?
      end
    end
  end
end
