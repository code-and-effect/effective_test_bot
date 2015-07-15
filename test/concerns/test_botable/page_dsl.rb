# This DSL gives a class level and an instance level way of calling specific tests
#
# class PostsTest < ActionDispatch::IntegrationTest
#   page_test(posts_path, User.first)
#
#   test 'a one-off action' do
#     page_action_test(posts_path, User.first)
#   end
# end


module TestBotable
  module PageDsl
    extend ActiveSupport::Concern

    module ClassMethods

      # This DSL method just defines a new test that calls the instance method here
      # Lets you type this as a class method so it looks nice at the top of a test file, like shoulda :)
      def page_test(path, user, options = {})
        tests_prefix = test_bot_prefix('page_test', options.delete(:label)) # returns a string something like "crud_test (3)" when appropriate
        define_method("#{tests_prefix} #{path}") { page_action_test(path, user, options) }
      end

    end # /ClassMethods

    # Instance Methods

    # This will allow you to run a page_test method in a test
    # page_action_test(:about_path, User.first, skip: :status)
    def page_action_test(path, user, options = {})
      begin
        test_options = self.class.parse_test_bot_options(options.merge(user: user, page_path: path)) # returns a Hash of let! options
      rescue => e
        raise "Error: #{e.message}.  Expected usage: page_test(:about_path, User.first, options_hash)"
      end

      test_options.each { |k, v| self.class.let(k) { v } } # Using the regular let(:foo) { 'bar'} syntax

      self.send(:test_bot_page_test) # Just the one test so far
    end

  end
end
