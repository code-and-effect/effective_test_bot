# This DSL gives a class level and an instance level way of calling specific test suite
#
# class AboutTest < ActionDispatch::IntegrationTest
#   redirect_test('/about', '/new-about', User.first)
#
#   test 'a one-off action' do
#     redirect_action_test('/about', '/new-about', User.first)
#   end
# end

module TestBotable
  module RedirectDsl
    extend ActiveSupport::Concern

    module ClassMethods

      def redirect_test(from_path, to_path, user, options = {})
        options[:current_test] = options.delete(:label) || "#{from_path} to #{to_path}"
        return if EffectiveTestBot.skip?(options[:current_test])

        method_name = test_bot_method_name('redirect_test', options[:current_test])

        define_method(method_name) { redirect_action_test(from_path, to_path, user, options) }
      end
    end

    # Instance Methods - Call me from within a test
    def redirect_action_test(from_path, to_path, user, options = {})
      begin
        assign_test_bot_lets!(options.reverse_merge!(from_path: from_path, to_path: to_path, user: user))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: redirect_action_test('/about', '/new-about', User.first)"
      end

      self.send(:test_bot_redirect_test)
    end

  end
end
