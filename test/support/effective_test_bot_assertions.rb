module EffectiveTestBotAssertions
  def assert_signed_in
    visit new_user_session_path
    assert_content I18n.t('devise.failure.already_authenticated')
    assert page.has_no_selector?('form#new_user')
  end

  def assert_signed_out
    visit new_user_session_path
    refute_content I18n.t('devise.failure.already_authenticated')
    assert page.has_selector?('form#new_user')
  end

  def assert_page_title(title = :any, message = 'expected page title to be present')
    if title.present? && title != :any
      assert_title(title) # Capybara TitleQuery, match this text
    else
      title = (page.find(:xpath, '//title', visible: false) rescue nil)
      assert title.present?, message
    end
  end

  def assert_page_status(status = 200)
    assert_equal status, page.status_code, "expected page to load with #{status} HTTP status code"
  end

  def assert_no_js_errors
    errors = page.driver.error_messages
    assert_equal 0, errors.size, errors.ai
  end

  # assert_flash
  # assert_flash :success
  # assert_flash :error, 'there was a specific error'
  def assert_flash(level = nil, message = nil)
    if message.present?
      assert_equal message, flash[level.to_s]
    elsif level.present?
      assert flash[level.to_s].present?, "expected flash[#{level}] to be present"
    else
      assert flash.present?, 'expected flash to be present'
    end
  end

end
