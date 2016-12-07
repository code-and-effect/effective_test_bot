module EffectiveTestBot
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc "Creates an EffectiveTestBot initializer in your application."

      source_root File.expand_path('../../templates', __FILE__)

      def install_minitest
        return if File.exists?('test/test_helper.rb')
        puts '[effective_test_bot] installing minitest'
        run 'bundle exec rails generate minitest:install'
      end

      def copy_initializer
        template ('../' * 3) +  'config/effective_test_bot.rb', 'config/initializers/effective_test_bot.rb'
      end

      def overwrite_minitest
        template 'test_helper.rb', 'test/test_helper.rb'
      end

      def thank_you
        puts "Thanks for using EffectiveTestBot"
        puts "Make sure you create a user in your db/seeds.rb, test/fixtures/users.yml, or test/fixtures/seeds.rb"
        puts "Run `rake test:bot:environment` once to ensure the testing environment is correctly configured"
        puts "Test your app with 'rake test:bot'"
      end
    end
  end
end
