require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  #driven_by :selenium, using: :chrome, screen_size: [1024, 768]
  driven_by :selenium_chrome_headless, screen_size: [1024, 768]

  include Warden::Test::Helpers if defined?(Devise)
  include EffectiveTestBot::DSL
end
