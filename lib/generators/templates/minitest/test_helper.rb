ENV['RAILS_ENV'] = 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/rails/capybara'
require 'minitest/pride'
require 'minitest/reporters'

require 'shoulda-matchers'
require 'shoulda'

require 'capybara/webkit'
require 'capybara-screenshot/minitest'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  include Capybara::Assertions
  include Capybara::Screenshot::MiniTestPlugin
end

Capybara.default_driver = :webkit
Capybara.javascript_driver = :webkit
Capybara::Screenshot.autosave_on_failure = true
Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara::Screenshot.webkit_options = { width: 1024, height: 768 }

#Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
