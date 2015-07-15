require 'test_helper'

module TestBot
  class ApplicationTest < ActionDispatch::IntegrationTest
    CRUD_ACTIONS = %w(index create new edit show update destroy) # Same order as resources :object creates them in

    class << self
      def initialize_tests
        routes = Rails.application.routes.routes.to_a
        crud_actions = Hash.new([])  # {posts: ['new', 'edit'], events: ['new', 'edit', 'show']}

        # ActionDispatch::Routing::PathRedirect is route.app.class for a 301, which has .defaults[:status] = 301


        routes.each_with_index do |route, index|
          controller = route.defaults[:controller]
          action = route.defaults[:action]

          #puts "#{route.name}_path | #{route.path.spec} | #{route.verb} | #{route.defaults[:controller]} | #{route.defaults[:action]}"

          next if controller.blank? || action.blank? || controller.include?('devise')

          # Accumulate all defined crud_actions on a controller, then call crud_test once we know all the actions
          if CRUD_ACTIONS.include?(action)
            crud_actions[controller] += [action]

            if controller != (routes[index+1].defaults[:controller] rescue :last) # If the next route isn't on the same controller as mine
              (namespace, resource) = namespace_and_resource_for(controller)

              next if resource.blank?

              begin
                crud_test(resource, User.first, label: controller, namespace: namespace, only: crud_actions[controller])
              rescue => e
                puts e.message
              end
            end
          elsif route.name.present? && route.verb.to_s.include?('GET')
            page_test("#{route.name}_path", User.first, route: route)
          else
            #define_method("app_test: #{route.name} ##{route.verb}") { page_test(route) }
            puts "skipping #{route.name}_path | #{route.path.spec} | #{route.verb} | #{route.defaults[:controller]} | #{route.defaults[:action]}"
          end
        end
      end

      private

      def namespace_and_resource_for(controller)
        (*namespace, klass) = controller.split('/')
        namespace = Array(namespace).join('/').presence

        # See if I can turn it into a model
        klass = klass.classify.safe_constantize

        return namespace, klass
      end
    end

    initialize_tests

  end

end
