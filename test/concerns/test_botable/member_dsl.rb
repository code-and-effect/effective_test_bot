# This DSL gives a class level and an instance level way of calling specific test suite
#
# class PostsTest < ActionDispatch::IntegrationTest
#   member_test(controller: 'admin/jobs', action: 'unarchive', user: User.first, member: Post.first)
#
#   test 'a one-off action' do
#     member_action_test(controller: 'admin/jobs', action: 'unarchive', user: User.first, member: Post.first)
#   end
# end

# A member_test assumes assumes route.name.present? && route.verb.to_s.include?('GET') && route.path.required_names == ['id']
# we HAVE TO build or have available one of these resources so we can pass the ID to it and see what happens :)

module TestBotable
  module MemberDsl
    extend ActiveSupport::Concern

    module ClassMethods
      def member_test(controller:, action:, user: nil, member: nil, label: nil, **options)
        options[:current_test] = label || "#{controller}##{action}"
        return if EffectiveTestBot.skip?(options[:current_test])

        method_name = test_bot_method_name('member_test', options[:current_test])

        define_method(method_name) { member_action_test(controller: controller, action: action, user: user, member: member, **options) }
      end

    end

    # Instance Methods - Call me from within a test
    def member_action_test(controller:, action:, user: nil, member:, **options)
      method_user = user || _test_bot_user(options[:current_test])

      begin
        assign_test_bot_lets!(options.reverse_merge!(resource: controller, action: action, user: method_user, member: member))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: member_test(controller: 'admin/jobs', action: 'unarchive', user: User.first, member: (Post.first || nil))"
      end

      self.send(:test_bot_member_test)
    end

  end
end
