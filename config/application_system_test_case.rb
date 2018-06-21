require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  include Warden::Test::Helpers if defined?(Devise)
  include EffectiveTestBot::DSL
end
