ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'minitest/fail_fast' if EffectiveTestBot.fail_fast?

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors) if respond_to?(:parallelize)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # From effective_test_bot. Loads db/seeds.rb and test/fixtures/seeds.rb file once. :all, :db, :test
  seeds :all
end

Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_silencer { |line| line =~ /minitest/ }
Rails.backtrace_cleaner.add_silencer { |line| line =~ /parallelization/ }

# rails test
# rails test:system
# rails test:bot:environment
# rails test:bot

# rails test:system TOUR=true
# rails test:bot TEST=posts#index