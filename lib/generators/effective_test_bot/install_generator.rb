module EffectiveTestBot
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc "Creates an EffectiveTestBot initializer in your application."

      source_root File.expand_path("../../templates", __FILE__)

      def install_rspec
        return if File.exists?('spec/spec_helper.rb')
        puts '[effective_test_bot] installing rspec'
        run 'bundle exec rails generate rspec:install'
      end

      def install_guard
        return if File.exists?('Guardfile')
        puts '[effective_test_bot] installing guard'
        run 'bundle exec guard init'
        puts ""
      end

      def explain_overwrite
        puts '[effective_test_bot] Successfully installed/detected: rspec-rails and guard.'
        puts ""
        puts 'Starting effective_test_bot specific installation tasks:'
        puts ""
        puts "You will be prompted to overwrite the default rspec-rails configuration"
        puts "files with those packaged inside the effective_test_bot gem."
        puts ""
        puts "If you have very specific existing rspec-rails configuration,"
        puts "you may want to skip (press 'n') to the following overwrites"
        puts "and refer to the GitHub documentation for this gem:"
        puts "https://github.com/code-and-effect/effective_test_bot"
        puts ""
        puts "Otherwise, press 'Y' to all the following prompts to automatically configure"
        puts "rspec-rails to run with guard, capybara-webkit, and effective_test_bot test coverage"
        puts ""
      end

      def copy_initializer
        template "effective_test_bot.rb", "config/initializers/effective_test_bot.rb"
      end

      def overwrite_rspec
        template 'rspec/.rspec', '.rspec'
        template 'rspec/rails_helper.rb', 'spec/rails_helper.rb'
        template 'rspec/spec_helper.rb', 'spec/spec_helper.rb'
      end

      def thank_you
        puts "Thanks for using EffectiveTestBot"
        puts "Run tests by typing 'guard' (and then <ENTER>) or 'rspec'"
      end
    end
  end
end
