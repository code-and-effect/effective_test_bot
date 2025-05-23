module EffectiveTestBotTestHelper
  # This makes sure capybara is done, and breaks out of any 'within' blocks
  def synchronize!
    page.document.find('html')
    wait_for_ajax
  end

  # https://gist.github.com/josevalim/470808#gistcomment-1268491
  def wait_for_ajax
    begin
      Timeout.timeout(Capybara.default_max_wait_time * 2) do
        loop until finished_all_ajax_requests?
      end
    rescue => e
      assert_no_ajax_requests
    end
  end

  def wait_for_active_job
    begin
      Timeout.timeout(Capybara.default_max_wait_time * 2) do
        if defined?(SuckerPunch)
          loop until SuckerPunch::Queue.all.length == 0
        else
          loop until ActiveJob::Base.queue_adapter.enqueued_jobs.count == 0
        end
      end
    rescue => e
      assert_no_active_jobs
    end
  end

  def finished_all_ajax_requests?
    ajax_request_count = page.evaluate_script('jQuery.active')
    ajax_request_count.blank? || ajax_request_count.zero?
  end

  # Because capybara-webkit can't make delete requests, we need to use rack_test
  # Makes a DELETE request to the given path as the given user
  # It leaves any existing Capybara sessions untouched
  def visit_delete(path, user)
    session = Capybara::Session.new(:rack_test, Rails.application)
    sign_in(user)
    session.driver.submit :delete, path, {}
    session.document.find('html')

    @visit_delete_page = session
  end

  def was_redirect?(from_path, to_path = nil)
    from_path != (to_path || page.current_path)
  end

  def try_script(script)
    page.execute_script("try { #{script}; } catch(e) {};")
  end

  # Calls capybara within do .. end if selector is present and bool is true
  def within_if(selector, bool = true, &block)
    (all(selector).length > 0 && bool) ? within(first(selector)) { yield } : yield
  end

  def within_each(selector, &block)
    all(selector).each { |field| within(field) { yield } }
  end

  def within_first(selector, &block)
    Array(all(selector).first).each { |field| within(field) { yield } }
  end

  def within_last(selector, &block)
    Array(all(selector).last).each { |field| within(field) { yield } }
  end

  def within_tab(name, &block)
    first("a.nav-link#tab-#{name.parameterize}").click
    within_first("div.tab-pane##{name.parameterize}") { yield }
  end

  def within_datatable_new_form(&block)
    click_on 'New'
    within_first('.col-inline-form') { yield }
  end
  alias_method :within_datatables_new_form, :within_datatable_new_form

  def with_time_travel(date, &block)
    Timecop.travel(date)
    retval = yield
    Timecop.return
    retval
  end

  def click_first(label)
    click_link(label, match: :first)
  end

  def click_dropdown_link(label)
    dropdown = first(".btn.dropdown-toggle")
    raise("Unable to find a .btn.dropdown-toggle") unless dropdown.present?

    dropdown.click
    within_first("div.dropdown-menu") { submit_form(label) }
  end

  def effective_bootstrap_custom_data_confirm?
    (page.evaluate_script('$.rails.effective_bootstrap_custom_data_confirm') rescue nil) ||
    (page.evaluate_script('window.Rails.effective_bootstrap_custom_data_confirm') rescue nil)
  end

  # EffectiveTestBot includes an after_filter on ApplicationController to set an http header
  # These values are 'from the last page submit or refresh'
  def response_code
    (page.evaluate_script('window.effective_test_bot.response_code')&.to_i rescue nil)
  end

  def flash(key = nil)
    flash = (page.evaluate_script('window.effective_test_bot.flash') rescue nil) || {}
    key ? flash[key.to_s] : flash
  end

  def assigns(key = nil)
    assigns = (page.evaluate_script('window.effective_test_bot.assigns') rescue nil)
    assigns = {} unless assigns.kind_of?(Hash)
    key ? assigns[key.to_s] : assigns
  end

  def current_user_assigns_key
    assigns.keys.find { |key| key.start_with?('current_') && key.end_with?('_user') } || 'current_user'
  end

  def current_user_assigns_class
    current_user_assigns_key.sub('current_', '').gsub('_', '::').classify.safe_constantize
  end

  def access_denied_exception
    return nil unless (page.evaluate_script('window.effective_test_bot.access_denied') rescue nil).present?

    {
      exception: page.evaluate_script('window.effective_test_bot.access_denied'),
      action: page.evaluate_script('window.effective_test_bot.action'),
      subject: page.evaluate_script('window.effective_test_bot.subject')
    }
  end

  def tsputs(message)
    @last_message ||= Time.zone.now
    now = Time.zone.now

    puts "[+ #{now - @last_message}] #{message}"
    @last_message = now
  end

end
