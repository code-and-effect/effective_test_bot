require 'timeout'

module EffectiveTestBotFormHelper
  # Intelligently fills a form with Faker based randomish input
  # Delegates the form fill logic to effective_test_bot_form_filler
  def fill_form(fills = {})
    fills = HashWithIndifferentAccess.new(fills) unless fills.kind_of?(HashWithIndifferentAccess)

    bootstrap_tabs = all("a[data-toggle='tab']")

    if bootstrap_tabs.length > 1
      fill_bootstrap_tabs_form(fills, bootstrap_tabs)
    else
      fill_form_fields(fills)
    end
    true
  end

  # This submits the form, while checking for html5 form validation errors and unpermitted params
  def submit_form(label = nil)
    assert_no_html5_form_validation_errors unless test_bot_skip?(:no_html5_form_validation_errors)
    assert_jquery_ujs_disable_with(label) unless test_bot_skip?(:jquery_ujs_disable_with)

    if test_bot_skip?(:no_unpermitted_params)
      click_submit(label)
    else
      with_raised_unpermitted_params_exceptions { click_submit(label) }
    end

    assert_no_unpermitted_params unless test_bot_skip?(:no_unpermitted_params)
    true
  end

  # Submit form after disabling any HTML5 validations
  def submit_novalidate_form(label = nil)
    page.execute_script "for(var f=document.forms,i=f.length;i--;)f[i].setAttribute('novalidate','');"
    click_submit(label)
    true
  end

  def clear_form
    all('input,select,textarea').each do |field|
      if field.tag_name == 'select' && field['class'].to_s.include?('select2') # effective_select
        within(field.parent) { first(:css, '.select2-selection__clear').try(:click) }
      end

      begin
        field.set('');
        save_test_bot_screenshot if EffectiveTestBot.tour_mode_extreme?
      rescue => e; end
    end

    true
  end

  # So it turns out capybara-webkit has no way to just move the mouse to an element
  # This kind of sucks, as we want to simulate mouse movements with the tour
  # Instead we manually trigger submit buttons and use the data-disable-with to
  # make the 'submit form' step look nice
  def click_submit(label)
    if EffectiveTestBot.screenshots?
      page.execute_script "$('input[data-disable-with]').each(function(i) { $.rails.disableFormElement($(this)); });"
      save_test_bot_screenshot
      page.execute_script "$('input[data-disable-with]').each(function(i) { $.rails.enableFormElement($(this)); });"
    end

    label.present? ? find(:link_or_button, label).click : first(:css, "input[type='submit']").click
    synchronize!
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
