module ActsAsTestBotable
  extend ActiveSupport::Concern

  module ClassMethods
    def crud_test(object_or_class, user, options = {})
      if options.kind_of?(Hash) == false
        puts "effective_test_bot: crud_test() third argument expecting a Hash of options"
        puts "effective_test_bot: crud_test(Post, User.first, namespace: :admin, except: [:show])"
        return
      end

      actions = [:index, :new, :create, :edit, :update, :show, :destroy]

      if options[:only] && options[:except]
        puts "effective_test_bot: cannot use both :only and :except" and return
      elsif options[:only]
        actions = Array(options[:only]).flatten.compact.map(&:to_sym)
      elsif options[:except]
        actions = (actions - Array(options[:except]).flatten.compact.map(&:to_sym))
      end

      let(:crud_actions_to_test) { actions }
      let(:controller_namespace) { options[:namespace] }
      let(:user) { user }

      if user.kind_of?(User) == false
        puts 'effective_test_bot: crud_test() second argument must be a User object' and return
      end

      if object_or_class.kind_of?(Class)
        if object_or_class.ancestors.include?(ActiveRecord::Base) == false
          puts "effective_test_bot: crud_test() first argument must be an ActiveRecord object" and return
        end

        if ((object_or_class.new().kind_of?(object_or_class) == false) rescue true)
          puts "effective_test_bot: failed to call #{object_or_class}.new(), unable to proceed" and return
        end

        resource_class = object_or_class
        resource = object_or_class.new()
      elsif object_or_class.kind_of?(ActiveRecord::Base)
        resource_class = object_or_class.class
        resource = object_or_class
      else
        puts 'effective_test_bot: first paramater must be an ActiveRecord object or class' and return
      end

      let(:resource_class) { resource_class }
      let(:resource_name) { resource_class.name.underscore }
      let(:resource) { resource }

      # Compute any explicitly passed attributes
      if object_or_class.kind_of?(ActiveRecord::Base)
        new_resource = resource_class.new()

        resource_attributes = {}.tap do |atts|
          resource.attributes.each { |k, v| atts[k] = v if new_resource.attributes[k] != v }
        end

        let(:resource_attributes) { resource_attributes }
      else
        let(:resource_attributes) { Hash.new() }
      end

      include ::CrudTest

      # This will run any CrudTest methods, in order, as it's defined in the file
      # Then the rest of the methods in whatever order they occur originally (:random, :alpha, :sorted)
      def self.runnable_methods
        ::CrudTest.public_instance_methods.map { |name| name.to_s if name.to_s.starts_with?('test_bot') }.compact + super.select { |name| !name.starts_with?('test_bot') }
      end
    end

  end
end
