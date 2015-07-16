module TestBotable
  module BaseDsl
    extend ActiveSupport::Concern

    module ClassMethods
      TEST_BOT_TEST_PREFIXES = ['crud_test', 'member_test', 'page_test']

      # Parses and validates lots of options
      # We translate some DSL methods into one consistent Hash here
      # The output is what gets sent to each test and defined as lets
      def parse_test_bot_options(options)
        raise 'expected options to be a Hash' unless options.kind_of?(Hash)
        raise 'expected a user' unless options[:user].kind_of?(User)

        options.merge({}.tap do |retval|
          retval[:controller_namespace] = options[:controller_namespace] || options[:namespace]

          skips = options[:skip] || options[:skips]
          unless skips.blank? || skips.kind_of?(Symbol) || (skips.kind_of?(Array) && skips.all? { |s| s.kind_of?(Symbol) })
            raise 'expected skips to be a Symbol or Array of Symbols'
          end
          retval[:skips] = Array(skips)

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

              retval[:controller_namespace] ||= namespace
              retval[:controller] = obj.dup

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

            retval[:resource] = resource
            retval[:resource_class] = resource_class
            retval[:resource_name] = resource_class.name.underscore
            retval[:resource_attributes] = resource_attributes
          end
        end)
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
      def test_bot_test_name(parent_label, label)
        number_of_tests = if label.blank?
          @num_defined_test_bot_tests ||= {}
          @num_defined_test_bot_tests[parent_label] = (@num_defined_test_bot_tests[parent_label] || 0) + 1
        end

        if label.present?
          "#{parent_label}: (#{label})"
        elsif number_of_tests > 1
          "#{parent_label}: (#{number_of_tests})"
        else
          "#{parent_label}:"
        end
      end
    end

    # Instance Methods
    # none

  end
end
