module EffectivePages
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc "Creates an EffectiveTestBot initializer in your application."

      source_root File.expand_path("../../templates", __FILE__)

      def copy_initializer
        template "effective_test_bot.rb", "config/initializers/effective_test_bot.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
