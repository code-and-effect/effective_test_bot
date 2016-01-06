# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module DeviseTest
  protected

  def test_bot_devise_sign_up_test
    visit new_user_registration_path

    assert_form('form#new_user') unless test_bot_skip?(:form)

    within_if('form#new_user', !test_bot_skip?(:form)) do
      fill_form(email: email, password: password, password_confirmation: password)
      submit_form
    end

    assert_page_normal

    assert_content I18n.t('devise.registrations.signed_up')
    assert User.find_by_email(email).present?
    assert_signed_in
  end

  def test_bot_devise_sign_in_valid_test
    User.new(email: email, password: password, password_confirmation: password).save(validate: false)

    visit new_user_session_path

    assert_form('form#new_user') unless test_bot_skip?(:form)

    within_if('form#new_user', !test_bot_skip?(:form)) do
      fill_form(email: email, password: password)
      submit_form
    end

    assert_page_normal

    assert_content I18n.t('devise.sessions.signed_in')
    assert_equal 1, User.find_by_email(email).sign_in_count
    assert_signed_in
  end

  def test_bot_devise_sign_in_invalid_test
    User.new(email: email, password: password, password_confirmation: password).save(validate: false)

    visit new_user_session_path

    assert_form('form#new_user') unless test_bot_skip?(:form)

    within_if('form#new_user', !test_bot_skip?(:form)) do
      fill_form(email: email, password: 'not-correct-password')
      submit_form
    end

    assert_page_normal

    assert_content I18n.t('devise.failure.invalid', authentication_keys: Devise.authentication_keys.join(', '))
    assert_signed_out
  end

end
