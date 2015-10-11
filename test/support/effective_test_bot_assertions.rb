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
    return if was_download? # If this was a download, it correctly won't have a page title

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
    assert errors.blank?, message || "(no_js_errors) Unexpected javascript error:\n#{errors.first.to_s}"
  end

  def assert_no_unpermitted_params(message = '(no_unpermitted_params) Expected no unpermitted params')
    assert_equal [], unpermitted_params, message
  end

  def assert_no_exceptions(message = nil)
    assert exceptions.blank?, message || "(no_exceptions) Unexpected exception:\n#{exceptions.join("\n")}\n========== End of rails server exception ==========\n"
  end

  # This must be run after submit_form()
  # It ensures there are no HTML5 validation errors that would prevent the form from being submit
  def assert_no_html5_form_validation_errors(message = nil)
    errors = all(':invalid', visible: false).map { |field| field['name'] }
    assert errors.blank?, message || "(no_html5_form_validation_errors) Unable to submit form, unexpected HTML5 validation error present on the following fields:\n#{errors.join("\n")}"
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
      errors = (assigns[key.to_s] || {})['errors']
      assert errors.blank?, message || "(no_assigns_errors) Unexpected @#{key} rails validation errors:\n#{errors}"
    else
      assigns.each do |key, value|
        errors = value['errors']
        assert errors.blank?, message || "(no_assigns_errors) Unexpected @#{key} rails validation errors:\n#{errors}"
      end
    end
  end

  # assert_assigns_errors :post
  def assert_assigns_errors(key, message = nil)
    errors = (assigns[key.to_s] || {})['errors']
    assert errors.present?, message || "(assigns_errors) Expected @#{key}.errors to be present"
  end

end
