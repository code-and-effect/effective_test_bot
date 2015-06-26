module TestBotable
  module CrudTest
    extend ActiveSupport::Concern

    CRUD_TESTS = [:new, :create_valid, :create_invalid, :edit, :update_valid, :update_invalid, :index, :show, :destroy]

    module ClassMethods

      # All this does is define a 'test_bot' method for each required action on this class
      # So that MiniTest will see the test functions and run them
      def crud_test(obj, user, options = {})
        # Check for expected usage
        unless (obj.kind_of?(Class) || obj.kind_of?(ActiveRecord::Base)) && user.kind_of?(User) && options.kind_of?(Hash)
          raise 'invalid parameters passed to crud_test(), expecting crud_test(Post || Post.new(), User.first, options_hash)'
        end

        test_options = crud_test_options(obj, user, options) # returns a Hash of let! options
        tests_prefix = crud_tests_prefix(options) # returns a string something like "test_bot (3)"

        crud_tests_to_define(options).each do |test|
          test_name = case test
            when :new               ; "#{tests_prefix} #new"
            when :create_valid      ; "#{tests_prefix} #create valid"
            when :create_invalid    ; "#{tests_prefix} #create invalid"
            when :edit              ; "#{tests_prefix} #edit"
            when :update_valid      ; "#{tests_prefix} #update valid"
            when :update_invalid    ; "#{tests_prefix} #update invalid"
            when :index             ; "#{tests_prefix} #index"
            when :show              ; "#{tests_prefix} #show"
            when :destroy           ; "#{tests_prefix} #destroy"
          end

          define_method(test_name) { crud_action_test(test, test_options) }
        end
      end

      # Parses and validates lots of options
      # The output is what gets sent to each test and defined as lets
      def crud_test_options(obj, user, options = {})
        # Make sure Obj.new() works
        if obj.kind_of?(Class) && (obj.new() rescue false) == false
          raise "effective_test_bot: failed to initialize object with #{obj}.new(), unable to proceed"
        end

        # Parse the resource and resource class
        resource = obj.kind_of?(Class) ? obj.new() : obj
        resource_class = obj.kind_of?(Class) ? obj : obj.class

        # If obj is an ActiveRecord object with attributes, Post.new(:title => 'My Title')
        # then compute any explicit attributes, so forms will be filled with those values
        resource_attributes = if obj.kind_of?(ActiveRecord::Base)
          empty = resource_class.new()
          {}.tap { |atts| resource.attributes.each { |k, v| atts[k] = v if empty.attributes[k] != v } }
        end || {}

        # Final options to call each test with
        {
          resource: resource,
          resource_class: resource_class,
          resource_name: resource_class.name.underscore,
          resource_attributes: resource_attributes,
          controller_namespace: options[:namespace],
          user: user
        }
      end

      # Run any test_bot tests first, in the order they're defined
      # then the rest of the tests with whatever order they come in
      def runnable_methods
        self.public_instance_methods.select { |name| name.to_s.starts_with?('test_bot') }.map(&:to_s) +
          super.reject { |name| name.starts_with?('test_bot') }
      end

      private

      # Parses the incoming options[:only] and [:except]
      # To only define the appropriate methods
      # This guarantees the functions will be defined in the same order as CRUD_TESTS
      def crud_tests_to_define(options)
        to_run = if options[:only]
          options[:only] = Array(options[:only]).flatten.compact.map(&:to_sym)
          options[:only] = options[:only] + [:create_valid, :create_invalid] if options[:only].delete(:create)
          options[:only] = options[:only] + [:update_valid, :update_invalid] if options[:only].delete(:update)

          CRUD_TESTS & options[:only]
        elsif options[:except]
          options[:except] = Array(options[:except]).flatten.compact.map(&:to_sym)
          options[:except] = options[:except] + [:create_valid, :create_invalid] if options[:except].delete(:create)
          options[:except] = options[:except] + [:update_valid, :update_invalid] if options[:except].delete(:update)

          CRUD_TESTS - options[:except]
        else
          CRUD_TESTS
        end
      end

      # You can't define multiple methods with the same name
      # So we need to create a unique name, where appropriate, that still looks good in MiniTest output
      def crud_tests_prefix(options)
        @num_defined_crud_tests = (@num_defined_crud_tests || 0) + 1

        if options[:label].present?
          "test_bot: (#{options[:label]})"
        elsif @num_defined_crud_tests > 1
          "test_bot: (#{@num_defined_crud_tests})"
        else
          'test_bot:'
        end
      end

    end

    # Instance Methods

    # This should allow you to run a crud_test method in a test
    # crud_action_test(:create_valid, Clinic, User.first)
    #
    # If obj is a Hash {:resource => ...} just skip over parsing options
    # And assume it's already been done (by the ClassMethod crud_test)
    def crud_action_test(test, obj, user = nil, options = {})
      if obj.kind_of?(Hash) && obj.key?(:resource)
        obj
      else
        # Check for expected usage
        unless (obj.kind_of?(Class) || obj.kind_of?(ActiveRecord::Base)) && user.kind_of?(User) && options.kind_of?(Hash)
          raise 'invalid parameters passed to crud_action_test(), expecting crud_action_test(:new, Post || Post.new(), User.first, options_hash)'
        end

        self.class.crud_test_options(obj, user, options)
      end.each { |k, v| self.class.let(k) { v } } # Using the regular let(:foo) { 'bar'} syntax

      self.send(test)
    end
  end
end
