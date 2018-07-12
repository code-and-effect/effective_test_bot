require 'test_helper'

require 'capybara'
require 'selenium-webdriver'

Capybara.register_driver :effective_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  ['headless', 'disable-gpu', 'window-size=1366x1366'].each { |arg| options.add_argument(arg) }

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :effective_headless

  include Warden::Test::Helpers if defined?(Devise)
  include EffectiveTestBot::DSL
end
