# This DSL gives a class level and an instance level way of calling specific test suite
#
# class DeviseTest < ActionDispatch::IntegrationTest
#   devise_test()
#
#   test 'a one-off action' do
#     devise_action_test(:sign_up)
#     devise_action_test(:sign_in_valid)
#     devise_action_test(:sign_in_invalid)
#   end
# end

module TestBotable
  module DeviseDsl
    extend ActiveSupport::Concern

    module ClassMethods

      def devise_test(options = {})
        label = options.delete(:label).presence

        [:sign_up, :sign_in_valid, :sign_in_invalid].each do |test|
          options[:current_test] = label || test
          next if EffectiveTestBot.skip?(options[:current_test])

          method_name = test_bot_method_name('devise_test', options[:current_test])

          define_method(method_name) { devise_action_test(test, options) }
        end
      end

    end

    # Instance Methods - Call me from within a test
    def devise_action_test(test, options = {})
      options[:email] ||= "unique-#{Time.zone.now.to_i}@example.com"
      options[:password] ||= '!Password123'
      options[:username] ||= 'unique-username'
      options[:login] ||= 'unique-login'
      options[:user] ||= User.new

      begin
        assign_test_bot_lets!(options)
      rescue => e
        raise "Error: #{e.message}.  Expected usage: devise_action_test(:sign_up)"
      end

      self.send("test_bot_devise_#{test}_test")
    end

  end
end
