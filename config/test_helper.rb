ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

require 'rake'
require 'rails/test_help'

require 'minitest/spec'
require 'minitest/reporters'
require 'minitest/fail_fast' if EffectiveTestBot.fail_fast?

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # For the let syntax
  extend Minitest::Spec::DSL
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_silencer { |line| line =~ /minitest/ }
#Rails.backtrace_cleaner.add_silencer { |line| line =~ /effective_test_bot/ }

###############################################
### Effective Test Bot specific stuff below ###
###############################################

Rails.application.load_tasks

# So the very first thing we do is consistently reset the database.
# This can be done with Snippet 1 or Snippet 2.
# Snippet 1 is faster, and will usually work. Snippet 2 should always work.

# Snippet 1:
Rake::Task['db:schema:load'].invoke
ActiveRecord::Migration.maintain_test_schema!

# Snippet 2:

# Rake::Task['db:drop'].invoke
# Rake::Task['db:create'].invoke
# Rake::Task['db:migrate'].invoke

# Now we populate our test data:
Rake::Task['db:fixtures:load'].invoke
Rake::Task['db:seed'].invoke
Rake::Task['test:load_fixture_seeds'].invoke # from effective_test_bot. Loads test/fixtures/seeds.rb
