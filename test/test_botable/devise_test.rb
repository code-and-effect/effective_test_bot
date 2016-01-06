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

    assert_signed_in('Expected @current_user to be present after sign up')
    assert User.where(email: email).first.present?, "Expected user to be present after submitting sign up form at #{new_user_registration_path}"
    assert_page_content(I18n.t('devise.registrations.signed_up')) unless test_bot_skip?(:page_content)
  end

  def test_bot_devise_sign_in_valid_test
    user = User.new(email: email, password: password, password_confirmation: password)
    user.username = username if user.respond_to?(:username)
    user.login = login if user.respond_to?(:login)
    user.save(validate: false)

    visit new_user_session_path

    assert_form('form#new_user') unless test_bot_skip?(:form)

    within_if('form#new_user', !test_bot_skip?(:form)) do
      fill_form(email: email, password: password, username: username, login: login)
      submit_form
    end

    assert_page_normal

    assert_signed_in
    assert_page_content(I18n.t('devise.sessions.signed_in')) unless test_bot_skip?(:page_content)

    if User.new().respond_to?(:sign_in_count)
      assert_equal 1, User.where(email: email).first.try(:sign_in_count), "Expected user sign in count to be incremented after signing in"
    end
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

    assert_signed_out
    assert_page_content(I18n.t('devise.failure.invalid', authentication_keys: Devise.authentication_keys.join(', '))) unless test_bot_skip?(:page_content)
  end

end
