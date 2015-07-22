require 'test_helper'

module TestBot
  class ApplicationTest < ActionDispatch::IntegrationTest
    CRUD_ACTIONS = %w(index create new edit show update destroy) # Same order as resources :object creates them in

    class << self

      # Go through every route, and run an appropriate test suite on it
      def initialize_tests
        puts 'test_bot scanning....'

        routes = Rails.application.routes.routes.to_a
        seen_actions = Hash.new([])  # {posts: ['new', 'edit'], events: ['new', 'edit', 'show']}

        #Rails.application.routes.recognize_path('/your/path/here')
        #Rails.application.routes.recognize_path('/admin/jobs/3/unarchive')
        # => {:action=>"unarchive", :controller=>"admin/jobs", :id=>"3"}

        routes.each_with_index do |route, index|
          controller = route.defaults[:controller]
          action = route.defaults[:action]

          # Devise Test
          if (controller || '').include?('devise')
            next if seen_actions['devise'].present?

            puts 'define devise test!!'
            seen_actions['devise'] = true # So we don't repeat it

          # Redirect Test
          elsif route.app.kind_of?(ActionDispatch::Routing::PathRedirect) && route.path.required_names.blank?
            path = route.path.spec.to_s
            route.path.optional_names.each { |name| path.sub!("(.:#{name})", '') } # Removes (.:format) from path
            redirect_test(path, route.app.path([], nil), User.first)

          # CRUD Test
          elsif is_crud_controller?(route)
            seen_actions[controller] += [action]

            next_controller = (routes[index+1].defaults[:controller] rescue :last)
            next_action = (routes[index+1].defaults[:action] rescue :last)

            # If we're done accumulating CRUD actions, launch the crud_test with all seen actions
            if controller != next_controller || CRUD_ACTIONS.include?(next_action) == false
              begin
                crud_test(controller, User.first, only: seen_actions.delete(controller))
              rescue => e
                puts e.message # Sometimes there is an object that can't be instantiated, so we still want to continue the application test
              end
            end

          # Member Test
          elsif route.verb.to_s.include?('GET') && route.path.required_names == ['id']
            member_test(controller, action, User.first)

          # Page Test
          elsif route.verb.to_s.include?('GET') && route.name.present?
            page_test("#{route.name}_path".to_sym, User.first, route: route, label: "#{route.name}_path")

          else
            puts "skipping #{route.name}_path | #{route.path.spec} | #{route.verb} | #{route.defaults[:controller]} | #{route.defaults[:action]}"

          end # / Routes
        end
      end

      private

      def is_crud_controller?(route)
        return false unless CRUD_ACTIONS.include?(route.defaults[:action])

        controller_klass = (route.app.controller(route.defaults) rescue nil) if route.defaults[:controller].present? && route.app.respond_to?(:controller)
        controller_instance = controller_klass.new() if controller_klass

        # Is this a CRUD capable controller?
        controller_instance && controller_instance.respond_to?(:new) && controller_instance.respond_to?(:create)
      end

    end

    initialize_tests

  end

end
