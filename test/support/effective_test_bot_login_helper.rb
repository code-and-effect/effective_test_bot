# This is all assuming you're running Devise

module EffectiveTestBotLoginHelper
  def as_user(user)
    sign_in(user); yield; logout
  end

  def sign_in(user) # Warden::Test::Helpers
    user.kind_of?(String) ? login_as(User.find_by_email!(user)) : login_as(user)
  end

  def sign_in_manually(email, password)
    visit new_user_session_path

    within('form#new_user') do
      fill_form(email: email, password: password)
      submit_form
    end
  end

  def sign_up(email = Faker::Internet.email, password = Faker::Internet.password)
    visit new_user_registration_path

    within('form#new_user') do
      fill_form(email: email, password: password, password_confirmation: password)
      submit_form
    end

    User.find_by_email(email)
  end
end
