require 'rails_helper'

if defined?(Devise) && defined?(User)

  feature 'Devise Sign Up' do
    let(:email) { "user_#{Time.now.to_i}@example.com" }
    let(:password) { "pass_#{Time.now.to_i}" }

    it 'allows a valid sign up' do
      visit new_user_registration_path

      within('form#new_user') do
        fill_in 'user_email', with: email
        fill_in 'user_password', with: password
        fill_in 'user_password_confirmation', with: password

        find('input[type=submit]').click
      end

      expect(page.status_code).to eq 200
      expect(page).to have_content I18n.t('devise.registrations.signed_up')

      user = User.find_by_email(email)
      expect(user.present?).to eq true
      expect(user.valid?).to eq true
    end
  end

end # /defined?(Devise)
