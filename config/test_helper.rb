ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

require 'rails/test_help'
require 'minitest/spec'
require 'minitest/reporters'
require 'minitest/fail_fast' if EffectiveTestBot.fail_fast?

class ActiveSupport::TestCase
  fixtures :all               # Loads all fixtures in test/fixtures/*.yml
  extend Minitest::Spec::DSL  # For the let syntax
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_silencer { |line| line =~ /minitest/ }
#Rails.backtrace_cleaner.add_silencer { |line| line =~ /effective_test_bot/ }

setup = ['db:schema:load', 'db:fixtures:load', 'db:seed', 'test:load_fixture_seeds'].join(' ')
system("rails #{setup} RAILS_ENV=test")

# rails test
# rails test:system
# rails test:bot:environment
# rails test:bot

# rails test:system TOUR=true
# rails test:bot TEST=posts#index
