# This DSL gives a class level and an instance level way of calling specific tests
#
# class PostsTest < ActionDispatch::IntegrationTest
#   member_test('admin/jobs', 'unarchive', User.first, Post.first)
#
#   test 'a one-off action' do
#     member_action_test('admin/jobs', 'unarchive', User.first)
#   end
# end

# The action_test assumes route.name.present? && route.verb.to_s.include?('GET') && route.path.required_names == ['id']
# we HAVE TO build or have available one of these resources so we can pass the ID to it and see what happens :)

module TestBotable
  module MemberDsl
    extend ActiveSupport::Concern

    module ClassMethods
      # This DSL method just defines a new test that calls the instance method here
      # Lets you type this as a class method so it looks nice at the top of a test file, like shoulda :)
      def member_test(controller, action, user, obj_to_param = nil, options = {})
        puts "CLASS LEVEL MEMBER TEST"
        test_name = test_bot_test_name('member_test', options.delete(:label) || "#{controller}##{action}") # returns a string something like "action_test (3)" when appropriate
        define_method(test_name) { member_action_test(controller, action, user, obj_to_param, options) }
      end

    end # /ClassMethods

    # Instance Methods

    # This will allow you to run a page_test method in a test
    def member_action_test(controller, action, user, member = nil, options = {})
        puts "INSTANCE LEVEL MEMBER_TEST"
      begin
        test_options = self.class.parse_test_bot_options(options.merge(resource: controller, action: action, user: user, member: member)) # returns a Hash of let! options
      rescue => e
        raise "Error: #{e.message}.  Expected usage: member_test('admin/jobs', 'unarchive', User.first, Post.first || nil)"
      end

      test_options.each { |k, v| self.class.let(k) { v } } # Using the regular let(:foo) { 'bar'} syntax

      self.send(:test_bot_member_test) # Just the one test so far
    end

  end
end
