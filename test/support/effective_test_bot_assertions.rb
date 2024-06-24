module EffectiveTestBotAssertions

  def assert_page_content(content, message: "(page_content) Expected page content :content: to be present")
    assert page.has_text?(/#{Regexp.escape(content)}/i, wait: 0), message.sub(':content:', content)
  end

  def assert_no_page_content(content, message: "(page_content) Expected page content :content: to be blank")
    assert page.has_no_text?(/#{Regexp.escape(content)}/i, wait: 0), message.sub(':content:', content)
  end

  def assert_signed_in(message: 'Expected @current_user to be present when signed in')
    visit(root_path)
    assert_page_normal

    assert assigns[current_user_assigns_key].present?, message
  end

  def assert_signed_out(message: 'Expected @current_user to be blank when signed out')
    visit(root_path)
    assert_page_normal
    assert assigns[current_user_assigns_key].blank?, message
  end

  def assert_no_exceptions(message: "(no_exceptions) Unexpected rails server exception:\n:exception:")
    # this file is created by EffectiveTestBot::Middleware when an exception is encountered in the rails app
    file = File.join(Dir.pwd, 'tmp', 'test_bot', 'exception.txt')
    return unless File.exist?(file)

    exception = File.read(file)
    File.delete(file)

    assert false, message.sub(':exception:', exception)
  end

  def assert_can_execute_javascript(message: "Expected page.evaluate_script() to be successful")
    error = nil; result = nil;

    begin
      result = page.evaluate_script('1+1').to_s
    rescue => e
      error = e.message
    end

    assert (result == '2'), "#{message}. Error was: #{error}"
  end

  def assert_jquery_present(message: "Expected jquery ($.fn.jquery) to be present")
    assert((page.evaluate_script('$.fn.jquery') rescue nil).to_s.length > 0, message)
  end

  def assert_jquery_ujs_present(message: "Expected rails' jquery_ujs ($.rails) to be present")
    assert((page.evaluate_script('$.rails') rescue nil).to_s.length > 0, message)
  end

  def assert_page_title(title = :any, message: '(page_title) Expected page title to be present')
    if title.present? && title != :any
      assert_title(title) # Capybara TitleQuery, match this text
    else
      title = (page.find(:xpath, '//title', visible: false) rescue nil)
      assert title.present?, message
    end
  end

  def assert_form(selector, message: "(form) Expected visible form with selector :selector: to be present")
    assert all(selector).present?, message.sub(':selector:', selector)
  end

  def assert_submit_input(message: "(submit_input) Expected one or more visible input[type='submit'] or button[type='submit'] to be present")
    assert all("input[type='submit'],button[type='submit']").present?, message
  end

  def assert_authorization(message: '(authorization) Expected authorized access')
    if response_code == 403
      exception = access_denied_exception

      info = [
        "Encountered a 403 Access Denied",
        ("(cannot :#{exception[:action]}, #{exception[:subject]})" if exception.present?),
        "on #{page.current_path} as user #{current_user || 'no user'}.",
        ("\nAdd assign_test_bot_access_denied_exception(exception) if defined?(EffectiveTestBot) to the very bottom of your ApplicationController's rescue_from block to gather more information." unless exception.present?),
      ].compact.join(' ')

      assert false, "#{message}.\n#{info}"
    end
  end

  def assert_current_path_changed(&block)
    raise('expected a block') unless block_given?

    before_path = page.current_path
    yield
    assert_no_current_path(before_path)
  end

  def assert_page_status(status = 200, message: '(page_status) Expected :status: HTTP status code')
    return if response_code == nil # This doesn't work well in some drivers
    assert_equal status, response_code, message.sub(':status:', status.to_s)
  end

  def assert_current_path(path, message: '(current_path) Expected current_path to be :path:')
    path = public_send(path) if path.kind_of?(Symbol)
    assert_equal path, page.current_path, message.sub(':path:', path.to_s)
  end

  # assert_redirect '/about'
  # assert_redirect '/about', '/about-us'
  def assert_redirect(from_path, to_path = nil, message: nil)
    if to_path.present?
      assert_equal to_path, page.current_path, message || "(redirect) Expected redirect from #{from_path} to #{to_path}"
    else
      refute_equal from_path, page.current_path, message || "(redirect) Expected redirect away from #{from_path}"
    end
  end

  def assert_no_ajax_requests(message: "(no_ajax_requests) :count: Unexpected AJAX requests present")
    active = (page.evaluate_script('$.active') rescue nil)
    assert (active.blank? || active.zero?), message.sub(':count:', active.to_s)
  end

  def assert_no_active_jobs(message: "(no_active_jobs) :count: Unexpected ActiveJob jobs present")
    jobs = if defined?(SuckerPunch)
      SuckerPunch::Queue.all.length
    else
      ActiveJob::Base.queue_adapter.enqueued_jobs.count
    end

    assert (jobs == 0), message.sub(':count:', jobs.to_s)
  end

  def assert_no_js_errors(message: nil, strict: false)
    error = ''

    begin
      error = page.driver.browser.manage.logs.get(:browser).first # headless_chrome
    rescue NotImplementedError
      return
    rescue => e
      return
    end

    if strict == false
      return if error.to_s.include?('Failed to load resource')

      if error.to_s.include?('WARNING')
        puts "(no_js_errors) Unexpected javascript warning (use strict=true to fail here):\n#{error}"
        return
      end
    end

    assert error.blank?, message || "(no_js_errors) Unexpected javascript error:\n#{error}"
  end

  def assert_no_flash_errors(message: "(no_flash_errors) Unexpected flash error:\n:flash_errors:")
    assert (!flash.key?('error') && !flash.key?('danger')), message.sub(':flash_errors:', flash.to_s)
  end

  # This must be run after submit_form()
  # It ensures there are no HTML5 validation errors that would prevent the form from being submit
  # Browsers seem to only consider visible fields, so we will to
  def assert_no_html5_form_validation_errors(message: nil)
    errors = all(':invalid', visible: true, wait: false).map { |field| field['name'].presence }.compact

    assert errors.blank?, message || "(no_html5_form_validation_errors) Unable to submit form, unexpected HTML5 validation error present on the following fields:\n#{errors.join("\n")}"
  end

  # Rails jquery-ujs data-disable-with
  # = f.button :submit, 'Save', data: { disable_with: 'Saving...' }
  def assert_jquery_ujs_disable_with(label = nil, message: nil)
    submits = label.present? ? all("input[type='submit']", text: label, wait: false) : all("input[type='submit']", wait: false)
    all_disabled_with = submits.all? { |submit| submit['data-disable-with'].present? }

    assert all_disabled_with, message || "(jquery_ujs_disable_with) Expected rails jquery-ujs data-disable-with to be present on #{(label || "all input[type='submit'] fields")}\nInclude it on your submit buttons by adding \"data: { disable_with: 'Saving...' }\""
  end

  # assert_flash
  # assert_flash :success
  # assert_flash :error, 'there was a specific error'
  def assert_flash(key = nil, value = nil, message: nil)
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
  # assert_assigns :current_user, 'there should a current user'
  def assert_assigns(key = nil, value = nil, message: nil)
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
  def assert_no_assigns_errors(key = nil, message: nil)
    if key.present?
      errors = (assigns[key.to_s] || {})['errors']
      assert errors.blank?, message || "(no_assigns_errors) Unexpected @#{key} rails validation errors:\n#{errors}"
    else
      assigns.each do |key, value|
        errors = (value['errors'] rescue false) if value.respond_to?(:[])
        assert errors.blank?, message || "(no_assigns_errors) Unexpected @#{key} rails validation errors:\n#{errors}"
      end
    end
  end

  # assert_assigns_errors :post
  def assert_assigns_errors(key, message: nil)
    errors = (assigns[key.to_s] || {})['errors']
    assert errors.present?, message || "(assigns_errors) Expected @#{key}.errors to be present"
  end

  def assert_no_email(&block)
    before = ActionMailer::Base.deliveries.map { |mail| {to: mail.to, subject: mail.subject} }
    retval = yield
    after = ActionMailer::Base.deliveries.map { |mail| {to: mail.to, subject: mail.subject} }

    diff = (after - before)

    assert diff.blank?, "(assert_no_email) #{diff.length} unexpected emails delivered: #{diff}"
    retval
  end

  # assert_effective_log { click_on('download.txt') }
  def assert_effective_log(status: nil, &block)
    raise('EffectiveLogging is not defined') unless defined?(EffectiveLogging)
    raise('expected a block') unless block_given?

    logs = (status.present? ? Effective::Log.where(status: status).all : Effective::Log.all)

    before = logs.count
    retval = yield
    after = logs.count

    assert (after - before == 1), "(assert_effective_log) Expected one log to have been created"
    retval
  end


  #include ActiveJob::TestHelper if defined?(ActiveJob::TestHelper)
  def assert_email_perform_enqueued_jobs
    perform_enqueued_jobs if respond_to?(:perform_enqueued_jobs)
  end

  # assert_email :new_user_sign_up
  # assert_email :new_user_sign_up, to: 'newuser@example.com'
  # assert_email from: 'admin@example.com'
  def assert_email(action = nil, perform: true, clear: nil, to: nil, from: nil, subject: nil, body: nil, message: nil, count: nil, plain_layout: nil, html_layout: nil, &block)
    retval = nil
    clear = (count || 0) < 2 if clear.nil?

    # Clear the queue of any previous emails first
    if perform
      assert_email_perform_enqueued_jobs
      raise('expected empty mailer queue. unable to clear it.') unless (assert_email_perform_enqueued_jobs.to_i == 0)
    end

    if clear
      ActionMailer::Base.deliveries.clear
      raise('expected empty mailer deliveries. unable to clear it.') unless (ActionMailer::Base.deliveries.length.to_i == 0)
    end

    before = ActionMailer::Base.deliveries.length

    if block_given?
      retval = yield
      assert_email_perform_enqueued_jobs if perform

      difference = (ActionMailer::Base.deliveries.length - before)

      if count.present?
        assert (difference == count), "(assert_email) Expected #{count} email to have been delivered, but #{difference} were instead"
      else
        assert (difference > 0), "(assert_email) Expected at least one email to have been delivered"
      end
    end

    if (action || to || from || subject || body || plain_layout || html_layout).nil?
      assert ActionMailer::Base.deliveries.present?, message || "(assert_email) Expected email to have been delivered"
      return retval
    end

    actions = ActionMailer::Base.instance_variable_get(:@mailer_actions)

    ActionMailer::Base.deliveries.each do |message|
      matches = true

      html_body = message.parts.find { |part| part.content_type.start_with?('text/html') }.try(:body).to_s.presence
      plain_body = message.parts.find { |part| part.content_type.start_with?('text/plain') }.try(:body).to_s.presence
      message_body = message.body.to_s

      matches &&= (actions.include?(action.to_s)) if action
      matches &&= (Array(message.to).include?(to)) if to
      matches &&= (Array(message.from).include?(from)) if from
      matches &&= (message.subject == subject) if subject

      if body && html_layout
        matches &&= html_body.to_s.gsub("\r\n", '').gsub("\n", '').include?(">#{body}<")
      elsif body
        matches &&= (plain_body == body || message_body == body)
      end

      matches &&= (html_body.present? && html_body.include?('<meta')) if html_layout
      matches &&= (html_body.blank? && plain_body.blank? && message_body.exclude?('<meta')) if plain_layout

      return retval if matches
    end

    expected = [
      ("action: #{action}" if action),
      ("to: #{to}" if to),
      ("from: {from}" if from),
      ("subject: #{subject}" if subject),
      ("body: #{body}" if body),
      ("an HTML layout" if html_layout),
      ("no HTML layout" if plain_layout),
    ].compact.to_sentence

    assert false, message || "(assert_email) Expected email with #{expected} to have been delivered"
  end

  def assert_access_denied(message: nil)
    assert_equal 403, response_code, message || "Expected response code 403 when access denied, but it was: #{response_code || 'nil'}"
    assert_content 'Access Denied'
    assert_no_exceptions
  end

end
