# This DSL gives a class level and an instance level way of calling specific tests
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

    CRUD_TESTS = [:new, :create_valid, :create_invalid, :edit, :update_valid, :update_invalid, :index, :show, :destroy]

    module ClassMethods

      # All this does is define a 'test_bot' method for each required action on this class
      # So that MiniTest will see the test functions and run them
      def crud_test(resource, user, options = {})
        tests_prefix = test_bot_prefix('crud_test', options.delete(:label)) # returns a string something like "crud_test (3)" when appropriate

        # In the class method, this value is a Hash, in the instance method it's expecting an Array
        skips = options.delete(:skip) || options.delete(:skips) || {} # So you can skip sub tests
        raise 'invalid skip syntax, expecting skip: {create_invalid: [:path]}' unless skips.kind_of?(Hash)

        only = options.delete(:only)
        except = options.delete(:except)

        begin
          test_options = parse_test_bot_options(options.merge(user: user, resource: resource)) # returns a Hash of let! options
        rescue => e
          raise "Error: #{e.message}.  Expected usage: crud_test(Post || Post.new, User.first, options_hash)"
        end

        crud_tests_to_define(only, except).each do |test|
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

          if skips[test].present?
            define_method(test_name) { crud_action_test(test, test_options.merge(skips: Array(skips[test]))) }
          else
            define_method(test_name) { crud_action_test(test, test_options) }
          end
        end
      end

      private

      # Parses the incoming options[:only] and [:except]
      # To only define the appropriate methods
      # This guarantees the functions will be defined in the same order as CRUD_TESTS
      def crud_tests_to_define(only, except)
        if only
          only = Array(only).flatten.compact.map(&:to_sym)
          only = only + [:create_valid, :create_invalid] if only.delete(:create)
          only = only + [:update_valid, :update_invalid] if only.delete(:update)

          CRUD_TESTS & only
        elsif except
          except = Array(except).flatten.compact.map(&:to_sym)
          except = except + [:create_valid, :create_invalid] if except.delete(:create)
          except = except + [:update_valid, :update_invalid] if except.delete(:update)

          CRUD_TESTS - except
        else
          CRUD_TESTS
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
        begin
          self.class.parse_test_bot_options(options.merge(user: user, resource: obj)) # returns a Hash of let! options
        rescue => e
          raise "Error: #{e.message}.  Expected usage: crud_action_test(:new, Post || Post.new, User.first, options_hash)"
        end
      end.each { |k, v| self.class.let(k) { v } } # Using the regular let(:foo) { 'bar'} syntax

      self.send("test_bot_#{test}_test") # test_label doesn't apply here, 'cause this is run inside a titled test already
    end
  end
end
