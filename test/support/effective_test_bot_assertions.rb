module EffectiveTestBotAssertions
  def assert_signed_in(message = nil)
    visit new_user_session_path
    assert_content I18n.t('devise.failure.already_authenticated') #, message || '(signed_in) Expected devise already_authenticated content to be present'
    assert page.has_no_selector?('form#new_user'), message || '(signed_in) Expected new_user form to be blank'
  end

  def assert_signed_out(message = nil)
    visit new_user_session_path
    refute_content I18n.t('devise.failure.already_authenticated') #, message || '(signed_out) Expected devise already_authenticated content to be blank'
    assert page.has_selector?('form#new_user'), message || '(signed_out) Expected new_user form to be present'
  end

  def assert_page_title(title = :any, message = '(page_title) Expected page title to be present')
    if title.present? && title != :any
      assert_title(title) # Capybara TitleQuery, match this text
    else
      title = (page.find(:xpath, '//title', visible: false) rescue nil)
      assert title.present?, message
    end
  end

  def assert_page_status(status = 200, message = '(page_status) Expected :status: HTTP status code')
    assert_equal status, page.status_code, message.sub(':status:', status.to_s)
  end

  def assert_current_path(path, message = '(current_path) Expected current_path to be :path:')
    path = public_send(path) if path.kind_of?(Symbol)
    assert_equal path, page.current_path, message.sub(':path', path.to_s)
  end

  # assert_redirect '/about'
  # assert_redirect '/about', '/about-us'
  def assert_redirect(from_path, to_path = nil, message = nil)
    if to_path.present?
      assert_equal to_path, page.current_path, message || "(redirect) Expected redirect from #{from_path} to #{to_path}"
    else
      refute_equal from_path, page.current_path, message || "(redirect) Expected redirect away from #{from_path}"
    end
  end


  def assert_no_js_errors(message = nil)
    errors = page.driver.error_messages
    assert_equal 0, errors.size, message || "(no_js_errors) Unexpected javascript error: #{errors.join(', ')}"
  end

  def assert_no_unpermitted_params(message = '(no_unpermitted_params) Expected no unpermitted params')
    assert_equal [], unpermitted_params, message
  end

  # assert_flash
  # assert_flash :success
  # assert_flash :error, 'there was a specific error'
  def assert_flash(key = nil, value = nil, message = nil)
    if key.present? && value.present?
      assert_equal value, flash[key.to_s], message || "(flash) Expected flash[#{key}] to equal #{value}. Instead, it was: #{value}"
    elsif key.present?
      assert flash[key.to_s].present?, message || "(flash) Expected flash[#{key}] to be present"
    else
      assert flash.present?, message || '(flash) Expected flash to be present'
    end
  end

  # assert_assigns
  # assert_assigns :current_user
  # assert_assigns :current_user, true
  def assert_assigns(key = nil, value = nil, message = nil)
    if key.present? && value.present?
      assert_equal value, assigns[key.to_s], message || "(assigns) Expected assigns[#{key}] to equal #{value}. Instead, it was: #{value}"
    elsif key.present?
      assert assigns[key.to_s].present?, message || "(assigns) Expected @#{key} to be assigned"
    else
      assert assigns.present?, message || '(assigns) Expected assigns to be present'
    end
  end

  # assert_no_assigns_errors
  # assert_no_assigns_errors :post
  def assert_no_assigns_errors(key = nil, message = nil)
    if key.present?
      assert_equal [], ((assigns[key.to_s] || {})['errors'] || []), message || "(no_assigns_errors) Expected @#{key}[:errors] to be blank.  Instead, it was: #{assigns}"
    else
      assigns.each do |key, value|
        assert_equal [], (value['errors'] || []), message || "(no_assigns_errors) Expected @#{key}[:errors] to be blank"
      end
    end
  end

  # assert_assigns_errors :post
  def assert_assigns_errors(key, message = nil)
    refute_equal [], ((assigns[key.to_s] || {})['errors'] || []), message || "(assigns_errors) Expected @#{key}[:errors] to be present"
  end

end
