require 'test_helper'

module TestBot
  class ApplicationTest < ActionDispatch::IntegrationTest
    def self.initialize_tests
      Rails.application.routes.routes.to_a.first(2).each_with_index do |route, index|
        next if index == 0 # skip /assets

        define_method("app_test: #{route.name} ##{route.verb}") { page_test(route) }
      end
    end

    initialize_tests

    def self.runnable_methods
      public_instance_methods.select { |name| name.to_s.starts_with?('app_test') }.map(&:to_s) + super
    end

    private

    def page_test(route)
      puts "PAGE TEST CALLED WITH #{route.name}"

      visit send("#{route.name}_path")
      page.save_screenshot(route.name + '.png')

      assert 200, page.status_code
    end

  end

end
