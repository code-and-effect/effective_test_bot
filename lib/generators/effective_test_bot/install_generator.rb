module EffectiveTestBot
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc 'Creates an EffectiveTestBot initializer in your application.'

      source_root File.expand_path('../../templates', __FILE__)

      def copy_initializer
        template ('../' * 3) +  'config/effective_test_bot.rb', 'config/initializers/effective_test_bot.rb'
      end

      def copy_test_helper
        template ('../' * 3) +  'config/test_helper.rb', 'test/test_helper.rb'
        template ('../' * 3) +  'config/application_system_test_case.rb', 'test/application_system_test_case.rb'
      end

      def thank_you
        puts "Thanks for using EffectiveTestBot"
        puts "Make sure you create a user in your db/seeds.rb, test/fixtures/users.yml, or test/fixtures/seeds.rb"
        puts "Run `rails test:bot:environment` once to ensure the testing environment is correctly configured"
        puts "Test your app with 'rails test:bot'"
      end
    end
  end
end
