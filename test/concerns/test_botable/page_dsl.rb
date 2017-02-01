# This DSL gives a class level and an instance level way of calling specific test suite
#
# class PostsTest < ActionDispatch::IntegrationTest
#   page_test(path: :posts_path, user: User.first)
#
#   test 'a one-off action' do
#     page_action_test(path: :posts_path, user: User.first)
#   end
# end


module TestBotable
  module PageDsl
    extend ActiveSupport::Concern

    module ClassMethods

      def page_test(path:, user: nil, label: nil, **options)
        options[:current_test] = label || path.to_s
        return if EffectiveTestBot.skip?(options[:current_test])

        method_name = test_bot_method_name('page_test', options[:current_test])
        method_user = user || _test_bot_user(method_name)

        define_method(method_name) { page_action_test(path: path, user: method_user, **options) }
      end

    end

    # Instance Methods - Call me from within a test
    def page_action_test(path:, user: _test_bot_user(), **options)
      begin
        assign_test_bot_lets!(options.reverse_merge!(user: user, page_path: path))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: page_action_test(path: root_path, user: User.first)"
      end

      self.send(:test_bot_page_test)
    end

  end
end
