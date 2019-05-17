ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'minitest/fail_fast' if EffectiveTestBot.fail_fast?
require 'minitest/reporters'
require 'minitest/spec'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors) if respond_to?(:parallelize)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Loads your db/seeds.rb and test/fixtures/seeds.rb before all tests run. Valid options are :all :db and :test
  seeds :all

  extend Minitest::Spec::DSL # For the let syntax
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_silencer { |line| line =~ /minitest/ }
Rails.backtrace_cleaner.add_silencer { |line| line =~ /parallelization/ }

# rails test
# rails test:system
# rails test:bot:environment
# rails test:bot
# rails test:bot:fails
# rails test:bot:fail

# rails test:system TOUR=true
# rails test:bot TEST=posts#index