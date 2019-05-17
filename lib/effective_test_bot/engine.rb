module EffectiveTestBot
  class Engine < ::Rails::Engine
    engine_name 'effective_test_bot'

    config.autoload_paths += Dir["#{config.root}/test/test_botable/", "#{config.root}/test/concerns/", "#{config.root}/test/support/"]
    # config.autoload_paths += Dir["#{config.root}/test/test_botable/**/"]
    # config.autoload_paths += Dir["#{config.root}/test/concerns/**/"]
    # config.autoload_paths += Dir["#{config.root}/test/support/**/"]

    # Set up our default configuration options.
    initializer 'effective_test_bot.defaults', before: :load_config_initializers do |app|
      # Set up our defaults, as per our initializer template
      eval File.read("#{config.root}/config/effective_test_bot.rb")
    end

    initializer 'effective_test_bot.middleware' do |app|
      if Rails.env.test?
        Rails.application.config.middleware.use EffectiveTestBot::Middleware
      end
    end

    initializer 'effective_test_bot.email_logger' do |app|
      if Rails.env.test?
        ActiveSupport.on_load :action_mailer do
          ActionMailer::Base.send :include, ::EffectiveTestBotMailerHelper
          ActionMailer::Base.send :after_action, :assign_test_bot_mailer_info
        end
      end
    end

    initializer 'effective_test_bot.assign_assign_headers' do
      if Rails.env.test?
        ActiveSupport.on_load :action_controller do
          ActionController::Base.send :include, ::EffectiveTestBotControllerHelper

          ActionController::Base.send :before_action, :expires_now # Prevent 304 Not Modified caching
          ActionController::Base.send :after_action, :assign_test_bot_payload
        end
      end
    end

    # Provide the seeds DSL in Ac
    initializer 'effective_test_bot.test_case' do |app|
      if Rails.env.test?
        ActiveSupport.on_load :active_record do
          ActiveSupport::TestCase.send :include, TestSeedable::Seed
        end
      end
    end

  end
end
