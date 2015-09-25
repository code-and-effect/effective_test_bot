# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module DeviseTest
  protected

  def test_bot_devise_sign_up_test
    test_bot_skip?
    visit new_user_registration_path

    within('form#new_user') do
      fill_form(email: email, password: password, password_confirmation: password)
      submit_form
    end

    assert_page_normal

    assert_content I18n.t('devise.registrations.signed_up')
    assert User.find_by_email(email).present?
    assert_assigns :current_user
  end

  def test_bot_devise_sign_in_valid_test
    test_bot_skip?
    User.new(email: email, password: password, password_confirmation: password).save(validate: false)

    visit new_user_session_path

    within('form#new_user') do
      fill_form(email: email, password: password)
      submit_form
    end

    assert_page_normal

    assert_content I18n.t('devise.sessions.signed_in')
    assert_equal 1, User.find_by_email(email).sign_in_count
    assert_assigns :current_user
  end

  def test_bot_devise_sign_in_invalid_test
    test_bot_skip?
    User.new(email: email, password: password, password_confirmation: password).save(validate: false)

    visit new_user_session_path

    within('form#new_user') do
      fill_form(email: email, password: 'not-correct-password')
      submit_form
    end

    assert_page_normal

    assert_content I18n.t('devise.failure.invalid', authentication_keys: Devise.authentication_keys.join(', '))
    assert assigns[:current_user].blank?
  end

end
