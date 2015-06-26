module EffectiveTestBot
  class Engine < ::Rails::Engine
    engine_name 'effective_test_bot'

    config.autoload_paths += Dir["#{config.root}/test/test_botable/**/"] # Must be first
    config.autoload_paths += Dir["#{config.root}/test/concerns/**/"]
    config.autoload_paths += Dir["#{config.root}/test/support/**/"]

    # Set up our default configuration options.
    initializer "effective_test_bot.defaults", :before => :load_config_initializers do |app|
      # Set up our defaults, as per our initializer template
      eval File.read("#{config.root}/lib/generators/templates/effective_test_bot.rb")
    end

    initializer 'effective_test_bot.test_suite' do |app|
      Rails.application.config.to_prepare do
        ActionDispatch::IntegrationTest.include ActsAsTestBotable::CrudTest

        # A whole bunch of helper methods
        ActionDispatch::IntegrationTest.include EffectiveTestBotAssertions
        ActionDispatch::IntegrationTest.include EffectiveTestBotFormHelper
        ActionDispatch::IntegrationTest.include EffectiveTestBotLoginHelper
        ActionDispatch::IntegrationTest.include EffectiveTestBotTestHelper
      end
    end

    initializer 'effective_test_bot.assign_assign_headers' do
      ActiveSupport.on_load :action_controller do
        if Rails.env.test?
          ActionController::Base.send :include, ::EffectiveTestBotControllerHelper
          ActionController::Base.send :after_filter, :assign_test_bot_http_headers
        end
      end
    end

  end
end
