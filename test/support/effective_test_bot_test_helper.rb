module EffectiveTestBotTestHelper
  # This makes sure capybara is done, and breaks out of any 'within' blocks
  def synchronize!
    page.document.find('html')
    wait_for_ajax
  end

  # https://gist.github.com/josevalim/470808#gistcomment-1268491
  def wait_for_ajax
    begin
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop until finished_all_ajax_requests?
      end
    rescue => e
      assert_no_ajax_requests
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

  def was_download?(filename = nil)
    if filename.present?
      page.response_headers['Content-Disposition'].to_s.include?('filename=') &&
      page.response_headers['Content-Disposition'].to_s.include?(filename)
    else
      page.response_headers['Content-Disposition'].to_s.include?('filename=')
    end
  end

  # Calls capybara within do .. end if selector is present and bool is true
  def within_if(selector, bool = true, &block)
    (selector.present? && bool) ? within(selector) { yield } : yield
  end

  def click_first(label)
    click_link(label, match: :first)
  end

  # EffectiveTestBot includes an after_filter on ApplicationController to set an http header
  # These values are 'from the last page submit or refresh'
  def flash
    (JSON.parse(Base64.decode64(page.response_headers['Test-Bot-Flash'])) rescue {})
  end

  def assigns
    (JSON.parse(Base64.decode64(page.response_headers['Test-Bot-Assigns'])) rescue {})
  end

  def unpermitted_params
    (JSON.parse(Base64.decode64(page.response_headers['Test-Bot-Unpermitted-Params'])) rescue [])
  end

  def exceptions
    (JSON.parse(Base64.decode64(page.response_headers['Test-Bot-Exceptions'])) rescue [])
  end

end
