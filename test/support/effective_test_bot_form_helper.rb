require 'timeout'

module EffectiveTestBotFormHelper
  # Intelligently fills a form with Faker based randomish input
  # Delegates the form fill logic to effective_test_bot_form_filler
  def fill_form(fills = {})
    bootstrap_tabs = all("a[data-toggle='tab']", wait: false)

    form_fills = HashWithIndifferentAccess.new((EffectiveTestBot.form_fills || {}).merge(fills || {}))

    if bootstrap_tabs.length > 1
      fill_bootstrap_tabs_form(form_fills)
    else
      fill_form_fields(form_fills)
    end
    
    true
  end

  # This submits the form, while checking for html5 form validation errors and unpermitted params
  def submit_form(label = nil, last: false, debug: false)
    assert_no_html5_form_validation_errors unless test_bot_skip?(:no_html5_form_validation_errors)
    assert_jquery_ujs_disable_with(label) unless test_bot_skip?(:jquery_ujs_disable_with)

    if test_bot_skip?(:no_unpermitted_params)
      click_submit(label, last: last, debug: debug)
    else
      with_raised_unpermitted_params_exceptions { click_submit(label, last: last, debug: debug) }
    end

    assert_no_assigns_errors unless test_bot_skip?(:no_assigns_errors)
    assert_no_exceptions unless test_bot_skip?(:exceptions)
    assert_authorization unless test_bot_skip?(:authorization)
    assert_page_status unless test_bot_skip?(:page_status)

    true
  end

  # Submit form after disabling any HTML5 validations
  def submit_novalidate_form(label = nil)
    page.execute_script "for(var f=document.forms,i=f.length;i--;)f[i].setAttribute('novalidate','');"
    page.execute_script "$('form').find('[required]').removeAttr('required');"
    click_submit(label)
    true
  end

  # submit_stripe(content: 'Thank you!'), or
  #
  # submit_stripe
  # assert page.has_content?('Thank you for your support!', wait: 10)
  def submit_stripe(success_content: nil)
    stripe_iframe = find('iframe[name=stripe_checkout_app]')
    assert stripe_iframe.present?, 'unable to find stripe iframe'

    within_frame(stripe_iframe) do
      fill_in('Card number', with: '4242424242424242')
      fill_in('Expiry', with: "12#{Time.zone.now.year - 1999}")
      fill_in('CVC', with: '123')
      find_submit.click
    end

    synchronize! # Doesn't seem to work

    if success_content
      assert page.has_content?(success_content, wait: Capybara.default_max_wait_time * 10), "#{success_content} not found"
    end

    true
  end

  def clear_form
    all('input,select,textarea', wait: false).each do |field|
      if field.tag_name == 'select' && field['class'].to_s.include?('select2') # effective_select
        clear_effective_select(field)
      end

      begin
        field.set('')
        close_effective_date_time_picker(field) if field['class'].to_s.include?('effective_date')
        save_test_bot_screenshot if EffectiveTestBot.tour_mode_extreme?
      rescue => e; end
    end

    true
  end

  # So it turns out capybara-webkit has no way to just move the mouse to an element
  # This kind of sucks, as we want to simulate mouse movements with the tour
  # Instead we manually trigger submit buttons and use the data-disable-with to
  # make the 'submit form' step look nice
  def click_submit(label = nil, last: false, debug: false)
    submit = find_submit(label, last: last)

    if EffectiveTestBot.screenshots?
      try_script "$('input[data-disable-with]').each(function(i) { $.rails.disableFormElement($(this)); });"
      save_test_bot_screenshot
      try_script "$('input[data-disable-with]').each(function(i) { $.rails.enableFormElement($(this)); });"
    end

    if debug
      puts "Clicking: <#{submit.tag_name} id='#{submit['id']}' class='#{submit['class']}' name='#{submit['name']}' value='#{submit['value']}' href='#{submit['href']}' />"
    end

    submit.click

    if submit['data-confirm'] 
      effective_bootstrap_custom_data_confirm? ? submit.click : page.accept_alert
    end

    synchronize!

    save_test_bot_screenshot if EffectiveTestBot.screenshots? && page.current_path.present?

    true
  end

  # Keys are :value, should be one of :count, :minimum, :maximum, :between, :text, :id, :class, :visible, :exact, :exact_text, :match, :wait, :filter_se
  def find_submit(label = nil, last: false)
    submit = nil

    if label.present?
      submit = (find("input[type='submit'][value='#{label}'],button[type='submit'][value='#{label}']", match: :first) rescue nil)
      submit ||= find(:link_or_button, label, match: :first)

      if last
        submit = all("input[type='submit'][value='#{label}'],button[type='submit'][value='#{label}']").last
        submit ||= all('a', text: label).last
      end

      assert submit.present?, "TestBotError: Unable to find a visible submit link or button on #{page.current_path} with the label #{label}"
    else
      submit = (find("input[type='submit'],button[type='submit']", match: :first) rescue nil)
      submit = all("input[type='submit'],button[type='submit']").last if last
      assert submit.present?, "TestBotError: Unable to find a visible input[type='submit'] or button[type='submit'] on #{page.current_path}"
    end

    submit
  end

  def with_raised_unpermitted_params_exceptions(&block)
    action = nil

    begin  # This may only work with Rails >= 4.0
      action = ActionController::Parameters.action_on_unpermitted_parameters
      ActionController::Parameters.action_on_unpermitted_parameters = :raise
    rescue => e
      puts 'unable to assign config.action_on_unpermitted_parameters = :raise, (no_unpermitted_params) assertions may not work.'
    end

    yield

    ActionController::Parameters.action_on_unpermitted_parameters = action if action.present?
  end

end
