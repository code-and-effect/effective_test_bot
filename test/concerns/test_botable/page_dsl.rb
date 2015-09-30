# This DSL gives a class level and an instance level way of calling specific test suite
#
# class PostsTest < ActionDispatch::IntegrationTest
#   page_test(:posts_path, User.first)
#
#   test 'a one-off action' do
#     page_action_test(:posts_path, User.first)
#   end
# end


module TestBotable
  module PageDsl
    extend ActiveSupport::Concern

    module ClassMethods

      def page_test(path, user, options = {})
        options[:current_test] = options.delete(:label) || path.to_s

        method_name = test_bot_method_name('page_test', options[:current_test])
        return if EffectiveTestBot.skip?(options[:current_test])

        define_method(method_name) { page_action_test(path, user, options) }
      end

    end

    # Instance Methods - Call me from within a test
    def page_action_test(path, user, options = {})
      begin
        assign_test_bot_lets!(options.reverse_merge!(user: user, page_path: path))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: crud_action_test(:new, Post || Post.new, User.first, options_hash)"
      end

      self.send(:test_bot_page_test)
    end

  end
end
