require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium_chrome_headless, screen_size: [1366, 768]

  include Warden::Test::Helpers if defined?(Devise)
  include EffectiveTestBot::DSL
end
