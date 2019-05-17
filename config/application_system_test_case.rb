# Working as per Rails 6.0.0.rc1
require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  include Warden::Test::Helpers if defined?(Devise)
  include EffectiveTestBot::DSL
end

# "Connection not rolling back" snippets from previous rails versions
# These are some snippets that the internet has collected to fix test threading issues.
# They are unneeded with effective_test_bot. On my machine. But I leave them here as a reference.
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


