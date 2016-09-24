module EffectiveTestBotMailerHelper
  # This is included to ActionMailer::Base an after_filter
  # And allows the assert_email assertion to work
  def assign_test_bot_mailer_info
    message.instance_variable_set(:@mailer_class, self.class)
    message.instance_variable_set(:@mailer_action, action_name)
  end
end
