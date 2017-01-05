ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rake'
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/rails/capybara'
require 'minitest/pride'
require 'minitest/reporters'

require 'capybara/webkit'
require 'capybara-screenshot/minitest'
require 'capybara/slow_finder_errors'

require 'database_cleaner'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  use_transactional_fixtures = true
end

class Capybara::Rails::TestCase
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  include Capybara::Assertions
  include Capybara::Screenshot::MiniTestPlugin
  include Warden::Test::Helpers if defined?(Devise)

  include EffectiveTestBot::DSL

  def after_setup
    super()
    DatabaseCleaner.start
  end

  def after_teardown
    super()
    DatabaseCleaner.clean
    Capybara.reset_sessions!  # Some apps seem to need this to correctly reset the test_06:_capybara_can_sign_in
  end
end

Capybara.default_driver = :webkit
Capybara.javascript_driver = :webkit
Capybara::Screenshot.autosave_on_failure = true
Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara::Screenshot.webkit_options = { width: 1024, height: 768 }
Capybara::Webkit.configure { |config| config.allow_unknown_urls }

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# These three lines are needed as of minitest-reporters 1.1.2
Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_silencer { |line| line =~ /minitest/ }
Rails.backtrace_cleaner.add_silencer { |line| line =~ /effective_test_bot/ }

###############################################
### Effective Test Bot specific stuff below ###
###############################################

Rails.application.load_tasks

# So the very first thing we do is consistently reset the database.
# This can be done with Snippet 1 or Snippet 2.
# Snippet 1 is faster, and will usually work.  Snippet 2 should always work.

# Snippet 1:
Rake::Task['db:schema:load'].invoke
ActiveRecord::Migration.maintain_test_schema!

# Snippet 2:

# Rake::Task['db:drop'].invoke
# Rake::Task['db:create'].invoke
# Rake::Task['db:migrate'].invoke

# Now we populate our test data:
Rake::Task['db:fixtures:load'].invoke # There's just no way to get the seeds first, as this has to delete everything
Rake::Task['db:seed'].invoke
Rake::Task['test:load_fixture_seeds'].invoke # This is included by effective_test_bot.  It just runs the app's test/fixtures/seeds.rb if it exists

if EffectiveTestBot.fail_fast?
  require 'minitest/fail_fast'
end

# "Connection not rolling back" snippets
# These are some snippets that the internet has collected to fix test threading issues.
# They are unneeded with effective_test_bot.  On my machine. But I leave them here as a reference.
# Try one or both if you are having issues passing rake test:bot:environment

# class ActiveRecord::Base
#   mattr_accessor :shared_connection
#   @@shared_connection = nil

#   def self.connection
#     @@shared_connection || retrieve_connection
#   end
# end
# ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

# ActiveRecord::ConnectionAdapters::ConnectionPool.class_eval do
#   def current_connection_id
#     Thread.main.object_id
#   end
# end
