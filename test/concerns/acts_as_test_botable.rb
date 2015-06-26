module ActsAsTestBotable
  extend ActiveSupport::Concern

  included do
    include ActsAsTestBotable::CrudTest # The CrudTest module below
    include ::CrudTest # test/test_botable/crud_test.rb
  end

  module CrudTest
    extend ActiveSupport::Concern

    CRUD_TESTS = [:new, :create_valid, :create_invalid, :edit, :update_valid, :update_invalid, :index, :show, :destroy]

    module ClassMethods
      def crud_test(obj, user, options = {})
        # Check for expected usage
        unless (obj.kind_of?(Class) || obj.kind_of?(ActiveRecord::Base)) && user.kind_of?(User) && options.kind_of?(Hash)
          raise 'invalid parameters passed to crud_test(), expecting crud_test(Post || Post.new(), User.first, options_hash)'
        end

        test_options = parse_crud_test_options(obj, user, options)
        tests_to_run = parse_crud_tests_to_run(options)

        # You can't define a method with the exact same name
        # So we need to create a unique name here, that still looks good in MiniTest output
        @defined_crud_tests = (@defined_crud_tests || 0) + 1
        if options[:label].present?
          test_prefix = "test_bot: (#{label})"
        elsif @defined_crud_tests > 1
          test_prefix = "test_bot: (#{@defined_crud_tests})"
        else
          test_prefix = 'test_bot:'
        end

        tests_to_run.each do |test|
          case test
          when :new
            define_method("#{test_prefix} #new") { crud_action_test(:new, test_options) }
          when :create_valid
            define_method("#{test_prefix} #create valid") { crud_action_test(:create_valid, test_options) }
          when :create_invalid
            define_method("#{test_prefix} #create invalid") { crud_action_test(:create_invalid, test_options) }
          when :edit
            define_method("#{test_prefix} #edit") { crud_action_test(:edit, test_options) }
          when :update_valid
            define_method("#{test_prefix} #update valid") { crud_action_test(:update_valid, test_options) }
          when :update_invalid
            define_method("#{test_prefix} #update invalid") { crud_action_test(:update_invalid, test_options) }
          when :index
            define_method("#{test_prefix} #index") { crud_action_test(:index, test_options) }
          when :show
            define_method("#{test_prefix} #show") { crud_action_test(:show, test_options) }
          when :destroy
            define_method("#{test_prefix} #destroy") { crud_action_test(:destroy, test_options) }
          else
            puts "unknown test passed to crud_test: #{test}"
          end
        end
      end

      def parse_crud_test_options(obj, user, options = {})
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

      def parse_crud_tests_to_run(options)
        if options[:only]
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
    end

    # Instance Methods

    # This should allow you to run a crud_test method in a test
    # crud_test(:new, Clinic, User.first)
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

        self.class.parse_crud_test_options(obj, user, options)
      end.each { |k, v| self.class.let(k) { v } } # Using the regular let(:foo) { 'bar'} syntax

      self.send(test)
    end

  end # / CrudTest module

end
