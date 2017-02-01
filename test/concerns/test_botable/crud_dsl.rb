# This DSL gives a class level and an instance level way of calling specific test suite
#
# class PostsTest < ActionDispatch::IntegrationTest
#   crud_test(resource: (Post || 'admin/posts'), user: User.first, except: :show, skip: {create_valid: :path, update_invalid: [:path, :flash]})
#
#   test 'a one-off action' do
#     crud_action_test(test: :new, resource: Post, user: User.first, skip: :title)
#   end
# end

module TestBotable
  module CrudDsl
    extend ActiveSupport::Concern

    CRUD_TESTS = [:index, :new, :create_invalid, :create_valid, :show, :edit, :update_invalid, :update_valid, :destroy, (:tour if EffectiveTestBot.tour_mode?)].compact

    module ClassMethods

      # All this does is define a 'test_bot' method for each required action on this class
      # So that MiniTest will see the test functions and run them
      def crud_test(resource:, user: nil, label: nil, skip: {}, only: nil, except: nil, **options)
        # This skips paramaters is different than the initializer skips, which affect just the rake task

        # These are specificially for the DSL
        # In the class method, this value is a Hash, in the instance method it's expecting an Array
        raise 'invalid skip syntax, expecting skip: {create_invalid: [:path]}' unless skip.kind_of?(Hash)

        current_crud_tests = crud_tests_to_define(only, except)

        begin
          normalize_test_bot_options!(options.merge!(resource: resource, current_crud_tests: current_crud_tests))
        rescue => e
          raise "Error: #{e.message}.  Expected usage: crud_test(resource: (Post || Post.new), user: User.first, only: [:new, :create], skip: {create_invalid: [:path]})"
        end

        current_crud_tests.each do |test|
          options_for_method = options.dup

          options_for_method[:skip] = Array(skip[test]) if skip[test]
          options_for_method[:current_test] = [
            options[:controller_namespace].presence,
            options[:resource_name].pluralize
          ].compact.join('/') + '#' + test.to_s

          next if EffectiveTestBot.skip?(label || options_for_method[:current_test])

          method_name = test_bot_method_name('crud_test', label || options_for_method[:current_test])
          method_user = user || _test_bot_user(method_name)

          define_method(method_name) { crud_action_test(test: test, resource: resource, user: method_user, **options_for_method) }
        end
      end

      private

      # Parses the incoming options[:only] and [:except]
      # To only define the appropriate methods
      # This guarantees the functions will be defined in the same order as CRUD_TESTS
      def crud_tests_to_define(only, except)
        if only
          only = Array(only).flatten.compact.map { |x| x.to_sym }
          only = only + [:create_valid, :create_invalid] if only.delete(:create)
          only = only + [:update_valid, :update_invalid] if only.delete(:update)

          CRUD_TESTS & only
        elsif except
          except = Array(except).flatten.compact.map { |x| x.to_sym }
          except = except + [:create_valid, :create_invalid] if except.delete(:create)
          except = except + [:update_valid, :update_invalid] if except.delete(:update)

          CRUD_TESTS - except
        else
          CRUD_TESTS
        end
      end
    end

    # Instance Methods - Call me from within a test
    #
    # If obj is a Hash {:resource => ...} just skip over parsing options
    # And assume it's already been done (by the ClassMethod crud_test)
    def crud_action_test(test:, resource:, user: _test_bot_user(), **options)
      begin
        assign_test_bot_lets!(options.reverse_merge!(resource: resource, user: user))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: crud_action_test(test: :new, resource: (Post || Post.new), user: User.first)"
      end

      self.send("test_bot_#{test}_test")
    end
  end
end
