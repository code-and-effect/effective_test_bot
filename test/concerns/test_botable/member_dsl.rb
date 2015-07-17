# This DSL gives a class level and an instance level way of calling specific test suite
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

      def member_test(controller, action, user, obj_to_param = nil, options = {})
        test_name = test_bot_test_name('member_test', options.delete(:label) || "#{controller}##{action}")
        define_method(test_name) { member_action_test(controller, action, user, obj_to_param, options) }
      end

    end

    # Instance Methods - Call me from within a test
    def member_action_test(controller, action, user, member = nil, options = {})
      begin
        self.class.parse_test_bot_options(options.merge(resource: controller, action: action, user: user, member: member))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: member_test('admin/jobs', 'unarchive', User.first, Post.first || nil)"
      end.each { |k, v| self.class.let(k) { v } } # Using the regular let(:foo) { 'bar' } syntax

      self.send(:test_bot_member_test)
    end

  end
end
