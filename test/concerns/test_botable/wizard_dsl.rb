# This DSL gives a class level and an instance level way of calling specific test suite
#
# class PostsTest < ActionDispatch::IntegrationTest
#   wizard_test('/fee_wizard/step1', '/fee_wizard/step5', User.first)
#
#   test 'a one-off action' do
#     wizard_action_test('/fee_wizard/step1', '/fee_wizard/step5', User.first) do
#       puts page.current_path
#     end
#   end
# end

# A member_test assumes assumes route.name.present? && route.verb.to_s.include?('GET') && route.path.required_names == ['id']
# we HAVE TO build or have available one of these resources so we can pass the ID to it and see what happens :)

module TestBotable
  module WizardDsl
    extend ActiveSupport::Concern

    module ClassMethods

      def wizard_test(from_path, to_path, user, options = {})
        if to_path.present?
          options[:current_test] = options.delete(:label) || "#{from_path} to #{to_path}"
        else
          options[:current_test] = options.delete(:label) || "#{from_path}"
        end

        return if EffectiveTestBot.skip?(options[:current_test])

        method_name = test_bot_method_name('wizard_test', options[:current_test])

        define_method(method_name) { wizard_action_test(from_path, to_path, user, options) }
      end

    end

    # Instance Methods - Call me from within a test
    def wizard_action_test(from_path, to_path, user, options = {})
      begin
        assign_test_bot_lets!(options.reverse_merge!(from_path: from_path, to_path: to_path, user: user))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: wizard_action_test('/fee_wizard/step1', '/fee_wizard/step5', User.first)"
      end

      block_given? ? test_bot_wizard_test { yield } : test_bot_wizard_test
    end

  end
end
