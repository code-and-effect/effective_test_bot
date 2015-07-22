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

  def assert_page_title(title = :any, message = 'Expected page title to be present')
    if title.present? && title != :any
      assert_title(title) # Capybara TitleQuery, match this text
    else
      title = (page.find(:xpath, '//title', visible: false) rescue nil)
      assert title.present?, message
    end
  end

  def assert_page_status(status = 200, message = 'Expected :status: HTTP status code')
    assert_equal status, page.status_code, message.sub(':status:', status.to_s)
  end

  def assert_current_path(path, message = 'Expected current_path to be :path:')
    path = public_send(path) if path.kind_of?(Symbol)
    assert_equal path, page.current_path, message.sub(':path', path.to_s)
  end

  # assert_redirect '/about'
  # assert_redirect '/about', '/about-us'
  def assert_redirect(from_path, to_path = nil, message = nil)
    if to_path.present?
      assert_equal to_path, page.current_path, message || "Expected redirect from #{from_path} to #{to_path}"
    else
      refute_equal from_path, page.current_path, message || "Expected redirect away from #{from_path}"
    end
  end


  def assert_no_js_errors
    errors = page.driver.error_messages
    assert_equal 0, errors.size, "Unexpected javascript error: #{errors.join(', ')}"
  end

  def assert_no_unpermitted_params(message = 'Expected no unpermitted params')
    assert_equal [], unpermitted_params, message
  end

  # assert_flash
  # assert_flash :success
  # assert_flash :error, 'there was a specific error'
  def assert_flash(key = nil, value = nil)
    if key.present? && value.present?
      assert_equal value, flash[key.to_s]
    elsif key.present?
      assert flash[key.to_s].present?, "Expected flash[#{key}] to be present"
    else
      assert flash.present?, 'Expected flash to be present'
    end
  end

  # assert_assigns
  # assert_assigns :current_user
  # assert_assigns :current_user, true
  def assert_assigns(key = nil, value = nil)
    if key.present? && value.present?
      assert_equal value, assigns[key.to_s]
    elsif key.present?
      assert assigns[key.to_s].present?, "Expected @#{key} to be assigned"
    else
      assert assigns.present?, 'Expected assigns to be present'
    end
  end

  # assert_no_assigns_errors
  # assert_no_assigns_errors :post
  def assert_no_assigns_errors(key = nil)
    if key.present?
      assert_equal [], ((assigns[key.to_s] || {})['errors'] || []), "Expected @#{key}[:errors] to be blank"
    else
      assigns.each do |key, value|
        assert_equal [], (value['errors'] || []), "Expected @#{key}[:errors] to be blank"
      end
    end
  end

  # assert_assigns_errors :post
  def assert_assigns_errors(key)
    refute_equal [], ((assigns[key.to_s] || {})['errors'] || []), "Expected @#{key}[:errors] to be present"
  end

end
