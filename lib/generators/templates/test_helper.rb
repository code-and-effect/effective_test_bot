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
require 'capybara/slow_finder_errors'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # Add more helper methods to be used by all tests here...
  use_transactional_fixtures = true
end

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  include Capybara::Assertions
  include Capybara::Screenshot::MiniTestPlugin
  include Warden::Test::Helpers if defined?(Devise)

  # called before every single test
  # def setup
  # end

  # called after every single test
  def teardown
    Capybara.reset_sessions!
  end
end


Capybara.default_driver = :webkit
Capybara.javascript_driver = :webkit
Capybara::Screenshot.autosave_on_failure = true
Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara::Screenshot.webkit_options = { width: 1024, height: 768 }

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

### So this is EffectiveTestBot 'code' here
### That gets run just once before the whole test suite loads

# So the very first thing I do is set up a consistent database
Rake::Task['db:schema:load'].invoke
ActiveRecord::Migration.maintain_test_schema!

# or the following 3:

#Rake::Task['db:drop'].invoke
#Rake::Task['db:create'].invoke
#Rake::Task['db:migrate'].invoke

Rake::Task['db:fixtures:load'].invoke # There's just no way to get the seeds first, as this has to delete everything
Rake::Task['db:seed'].invoke

# Make all database transactions use the same thread, otherwise signing up in capybara won't get rolled back
# This must be run after the Rake::Tasks above
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
