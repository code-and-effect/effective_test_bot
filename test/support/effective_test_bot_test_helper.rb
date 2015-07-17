module EffectiveTestBotTestHelper
  # This makes sure capybara is done, and breaks out of any 'within' blocks
  def synchronize!
    page.document.find('html')
  end

  # Because capybara-webkit can't make delete requests, we need to use rack_test
  # Makes a DELETE request to the given path as the given user
  # It leaves any existing Capybara sessions untouched
  def visit_delete(path, user)
    session = Capybara::Session.new(:rack_test, Rails.application)
    sign_in(user)
    session.driver.submit :delete, path, {}
    session.document.find('html')

    # Assign the Flash and Assigns
    @flash = (JSON.parse(Base64.decode64(session.driver.response_headers['Test-Bot-Flash'])) rescue {})
    @assigns = (JSON.parse(Base64.decode64(session.driver.response_headers['Test-Bot-Assigns'])) rescue {})
    @unpermitted_params = (JSON.parse(Base64.decode64(session.driver.response_headers['Test-Bot-Unpermitted-Params'])) rescue [])
  end

  def was_redirect?(from_path, to_path = nil)
    from_path != (to_path || page.current_path)
  end

  # EffectiveTestBot includes an after_filter on ApplicationController to set an http header
  # that encodes the flash message, and some of the assigns
  def flash
    @flash ||= (JSON.parse(Base64.decode64(page.response_headers['Test-Bot-Flash'])) rescue {})
  end

  def assigns
    @assigns ||= (JSON.parse(Base64.decode64(page.response_headers['Test-Bot-Assigns'])) rescue {})
  end

  def unpermitted_params
    @unpermitted_params ||= (JSON.parse(Base64.decode64(page.response_headers['Test-Bot-Unpermitted-Params'])) rescue [])
  end
end
