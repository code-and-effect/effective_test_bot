module TestBotable
  module BaseDsl
    extend ActiveSupport::Concern

    module ClassMethods
      TEST_BOT_TEST_PREFIXES = ['crud_test', 'devise_test', 'member_test', 'page_test', 'redirect_test', 'wizard_test']

      # Parses and validates lots of options
      # This is a big manual merge wherein we translate some DSL methods into one consistent Hash here
      # The output is what gets sent to each test and defined as lets

      # {
      #   user: User<1> instance
      #   controller_namespace: 'admin'
      #   controller: 'jobs'
      #   skips: []
      #   resource: Post<1> instance
      #   resource_class: Post
      #   resource_name: 'post'
      #   resource_attributes: {:user_id => 3} attributes, if called with an instance of ActiveRecord with non-default attributes
      #   current_test: posts#new (if from the class level) or NIL if from the instance level
      # }
      #

      def normalize_test_bot_options!(options)
        raise 'expected options to be a Hash' unless options.kind_of?(Hash)
        raise 'expected key :user to be a User' unless options[:user].kind_of?(User)
        #raise 'expected key :current_test to be a String' unless options[:current_test].kind_of?(String)

        # Controller stuff
        options[:controller_namespace] ||= options[:namespace]

        # Skip stuff
        skips = options[:skip] || options[:skips]
        unless skips.blank? || skips.kind_of?(Symbol) || (skips.kind_of?(Array) && skips.all? { |s| s.kind_of?(Symbol) })
          raise 'expected skips to be a Symbol or Array of Symbols'
        end
        options[:skips] = Array(skips)

        # Resource could be an ActiveRecord Class, Instance of a class, or String
        # Build a resource stuff
        if options[:resource].present?
          obj = options[:resource]
          raise 'expected resource to be a Class or Instance or String' unless obj.kind_of?(Class) || obj.kind_of?(ActiveRecord::Base) || obj.kind_of?(String)

          if obj.kind_of?(String) # Let's assume this is a controller, 'admin/jobs', or just 'jobs', or 'jobs_controller'
            obj.sub!('_controller', '')

            (*namespace, klass) = obj.split('/')
            namespace = Array(namespace).join('/').presence

            # See if I can turn it into a model
            klass = klass.classify.safe_constantize

            raise "failed to constantize resource from string #{obj}, unable to proceed" unless klass.present?

            options[:controller_namespace] ||= namespace
            options[:controller] = obj.dup

            obj = klass
          end

          # Make sure Obj.new() works
          if obj.kind_of?(Class) && (obj.new() rescue false) == false
            raise "failed to initialize resource with #{obj}.new(), unable to proceed"
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

          options[:resource] = resource
          options[:resource_class] = resource_class
          options[:resource_name] = resource_class.name.underscore
          options[:resource_attributes] = resource_attributes
        end

        options[:normalized] = true

        options
      end

      # Run any test_bot tests first, in the order they're defined
      # then the rest of the tests with whatever order they come in
      def runnable_methods
        public_instance_methods.select do |name|
          name = name.to_s
          TEST_BOT_TEST_PREFIXES.any? { |prefix| name.starts_with?(prefix) }
        end.map(&:to_s) + super
      end

      protected

      # You can't define multiple methods with the same name
      # So we need to create a unique name, where appropriate, that still looks good in MiniTest output
      def test_bot_method_name(test_family, current_test)
        number_of_tests = if current_test.blank?
          @num_defined_test_bot_tests ||= {}
          @num_defined_test_bot_tests[test_family] = (@num_defined_test_bot_tests[test_family] || 0) + 1
        end

        # If we change the format here, also update effective_test_bot.skip? method
        if current_test.present?
          "#{test_family}: (#{current_test})"
        elsif number_of_tests > 1
          "#{test_family}: (#{number_of_tests})"
        else
          "#{test_family}:"
        end
      end
    end

    # Instance Methods


    # Using reverse_merge! in the dsl action_tests makes sure that the
    # class level can assign a current_test variable
    # wheras the action level ones it's not present.
    def assign_test_bot_lets!(options)
      lets = if options.kind_of?(Hash) && options[:normalized]
        options
      else
        self.class.normalize_test_bot_options!(options)
      end

      lets.each { |k, v| self.class.let(k) { v } } # Using the minitest spec let(:foo) { 'bar' } syntax

      # test_bot may leak some lets from one test to the next, if they're not overridden
      # I take special care to undefine just current test so far
      self.class.let(:current_test) { nil } if options[:current_test].blank?

      lets
    end

  end
end
