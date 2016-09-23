require 'test_helper'

# This gets run when we type `rake test:bot`
# Scan through every route and run a test suite against it

module TestBot
  class ApplicationTest < ActionDispatch::IntegrationTest
    CRUD_ACTIONS = %w(index create new edit show update destroy) # Same order as resources :object creates them in

    class << self

      # Go through every route, and run an appropriate test suite on it
      def initialize_tests
        @test_bot_user = User.first

        routes = Rails.application.routes.routes.to_a
        seen_actions = Hash.new([])  # {posts: ['new', 'edit'], events: ['new', 'edit', 'show']}

        routes.each_with_index do |route, index|
          controller = route.defaults[:controller]
          action = route.defaults[:action]

          # Devise Test
          if is_devise_controller?(route)
            next if seen_actions['devise'].present?
            seen_actions['devise'] = true # So we don't repeat it

            devise_test()

          # Redirect Test
          elsif is_redirect?(route)
            path = route.path.spec.to_s
            route.path.optional_names.each { |name| path.sub!("(.:#{name})", '') } # Removes (.:format) from path
            redirect_test(from: path, to: route.app.path([], nil))

          # CRUD Test
          elsif is_crud_controller?(route)
            seen_actions[controller] += [action]

            next_controller = (routes[index+1].defaults[:controller] rescue :last)
            next_action = (routes[index+1].defaults[:action] rescue :last)

            # If we're done accumulating CRUD actions, launch the crud_test with all seen actions
            if controller != next_controller || CRUD_ACTIONS.include?(next_action) == false
              begin
                only_tests = seen_actions.delete(controller)
                only_tests << :tour if EffectiveTestBot.tour_mode?

                crud_test(resource: controller, only: only_tests)
              rescue => e
                puts e.message # Sometimes there is an object that can't be instantiated, so we still want to continue the application test
              end
            end

          # Wizard Test
          elsif is_wicked_controller?(route)
            next if seen_actions[controller].present?
            seen_actions[controller] = true # So we don't repeat it

            wizard_test(from: "#{route.name}_path".to_sym, step: controller_instance(route).wizard_steps.first)

          # Member Test
          elsif is_member?(route)
            member_test(controller: controller, action: action)

          # Page Test
          elsif is_page?(route)
            page_test(path: "#{route.name}_path".to_sym, route: route, label: "#{route.name}_path")

          else
            unless EffectiveTestBot.silence_skipped_routes
              puts "skipping #{route.name}_path | #{route.path.spec} | #{route.verb} | #{route.defaults[:controller]} | #{route.defaults[:action]}"
            end

          end # / Routes
        end
      end

      protected

      def is_devise_controller?(route)
        return true if (route.defaults[:controller] || '').include?('devise')

        controller = controller_instance(route)
        controller.respond_to?(:devise_controller?) && controller.devise_controller?
      end

      def is_redirect?(route)
        route.app.kind_of?(ActionDispatch::Routing::PathRedirect) && route.path.required_names.blank?
      end

      def is_crud_controller?(route)
        return false unless CRUD_ACTIONS.include?(route.defaults[:action])

        controller = controller_instance(route)
        controller.respond_to?(:new) && controller.respond_to?(:create)
      end

      # https://github.com/schneems/wicked/
      def is_wicked_controller?(route)
        return false unless defined?(Wicked::Wizard)

        # This might be a wickeds controller, but it's a nested one, so we can't handle it anyway
        return false unless route.path.required_names == ['id']

        controller = controller_instance(route)
        return false unless controller.kind_of?(Wicked::Wizard)

        # So this is a Wicked::Wizard controller, we have to trick it into running an action to make the steps available
        controller.params = {}
        (controller.run_callbacks(:process_action) rescue false)

        controller.wizard_steps.present?
      end

      def is_member?(route)
        route.verb.to_s.include?('GET') && route.path.required_names == ['id']
      end

      def is_page?(route)
        route.verb.to_s.include?('GET') && route.name.present? && Array(route.path.required_names).blank? # This could eventually be removed to supported nested routes
      end

      private

      def controller_instance(route)
        return :none unless route.defaults[:controller] && route.defaults[:action]

        @_controller_instances ||= {}
        @_controller_instances[route.defaults[:controller]] ||= build_controller_instance(route)
      end

      def build_controller_instance(route)
        # Find the correct route.app that links to the controller
        # If there is a routing constraint, we have to traverse the route.app linked list to find the route with a controller
        route_app = route
        route_app = route_app.app while (route_app.respond_to?(:app) && route_app != route_app.app)

        return :none unless route_app.respond_to?(:controller)

        (route_app.controller(route.defaults).new() rescue :none)
      end

    end

    initialize_tests

  end

end
