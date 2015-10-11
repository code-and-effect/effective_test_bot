# This DSL gives a class level and an instance level way of calling specific test suite
#
# class PostsTest < ActionDispatch::IntegrationTest
#   crud_test(Post || 'admin/posts', User.first, except: :show, skip: {create_valid: :path, update_invalid: [:path, :flash]})
#
#   test 'a one-off action' do
#     crud_action_test(:new, Post, User.first, skip: :title)
#   end
# end

module TestBotable
  module CrudDsl
    extend ActiveSupport::Concern

    CRUD_TESTS = [:new, :create_valid, :create_invalid, :edit, :update_valid, :update_invalid, :index, :show, :destroy, (:tour if EffectiveTestBot.tour_mode?)].compact

    module ClassMethods

      # All this does is define a 'test_bot' method for each required action on this class
      # So that MiniTest will see the test functions and run them
      def crud_test(resource, user, options = {})
        # This skips paramaters is different than the initializer skips, which affect just the rake task

        # These are specificially for the DSL
        # In the class method, this value is a Hash, in the instance method it's expecting an Array
        skips = options.delete(:skip) || options.delete(:skips) || {} # So you can skip sub tests
        raise 'invalid skip syntax, expecting skip: {create_invalid: [:path]}' unless skips.kind_of?(Hash)

        label = options.delete(:label).presence
        only = options.delete(:only)
        except = options.delete(:except)

        begin
          normalize_test_bot_options!(options.merge!(user: user, resource: resource))
        rescue => e
          raise "Error: #{e.message}.  Expected usage: crud_test(Post || Post.new, User.first, only: [:new, :create], skip: {create_invalid: [:path]})"
        end

        crud_tests_to_define(only, except).each do |test|
          options_for_method = options.dup

          options_for_method[:skips] = Array(skips[test]) if skips[test]
          options_for_method[:current_test] = [
            options[:controller_namespace].presence,
            options[:resource_name].pluralize
          ].compact.join('/') + '#' + test.to_s

          next if EffectiveTestBot.skip?(label || options_for_method[:current_test])

          method_name = test_bot_method_name('crud_test', label || options_for_method[:current_test])

          define_method(method_name) { crud_action_test(test, resource, user, options_for_method) }
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
    def crud_action_test(test, resource, user = nil, options = {})
      begin
        assign_test_bot_lets!(options.reverse_merge!(user: user, resource: resource))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: crud_action_test(:new, Post || Post.new, User.first)"
      end

      self.send("test_bot_#{test}_test")
    end
  end
end
