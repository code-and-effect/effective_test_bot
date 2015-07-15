module TestBotable
  module PageDsl
    extend ActiveSupport::Concern

    module ClassMethods

      # This is like a dsl method...it just defines a new function and passes the same params
      # Lets you type this as a class method so it looks nice in a test :)
      def page_test(path, user, options = {})
        # Check for expected usage
        unless (path.kind_of?(Symbol) || path.kind_of?(String)) && user.kind_of?(User) && options.kind_of?(Hash)
          raise 'invalid parameters passed to page_test(), expecting page_test(:about_path, User.first, options_hash)'
        end

        tests_prefix = page_tests_prefix(options) # returns a string something like "page_test (3)"

        define_method("#{tests_prefix} #{path}") { page_action_test(path, user, options) }
      end

      # Parses and validates lots of options
      # The output is what gets sent to each test and defined as lets
      def page_test_options(path, user, options = {})
        # if path.kind_of?(Symbol)
        #   path = send(path) rescue raise("effective_test_bot: failed to evaluate #{path}, unable to proceed")
        # end

        # TODO: validate skips

        # Final options to call each test with
        {
          route: options[:route],
          page_path: path,
          user: user,
          skips: Array(options[:skip] || options[:skips])
        }
      end

      # Run any test_bot tests first, in the order they're defined
      # then the rest of the tests with whatever order they come in
      def runnable_methods
        public_instance_methods.select { |name| name.to_s.starts_with?('page_test') }.map(&:to_s) + super
      end

      private

      # You can't define multiple methods with the same name
      # So we need to create a unique name, where appropriate, that still looks good in MiniTest output
      def page_tests_prefix(options)
        if options[:label].present?
          "page_test: (#{options[:label]})"
        else
          'page_test:'
        end
      end

    end

    # Instance Methods

    # This should allow you to run a page_test method in a test
    # page_action_test(about_path, User.first, skip: :status)
    def page_action_test(path, user, options = {})
      # Check for expected usage
      unless (path.kind_of?(Symbol) || path.kind_of?(String)) && user.kind_of?(User) && options.kind_of?(Hash)
        raise 'invalid parameters passed to page_test(), expecting page_test(:about_path, User.first, options_hash)'
      end

      self.class.page_test_options(path, user, options).each { |k, v| self.class.let(k) { v } } # Using the regular let(:foo) { 'bar'} syntax

      self.send(:test_bot_page_test) # Just the one test so far
    end
  end
end
