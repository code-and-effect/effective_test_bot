module EffectiveTestBotMailerHelper
  # This is included to ActionMailer::Base an after_filter
  # And allows the assert_email assertion to work
  def assign_test_bot_mailer_info
    actions = ActionMailer::Base.instance_variable_get(:@mailer_actions)
    ActionMailer::Base.instance_variable_set(:@mailer_actions, Array(actions) + [action_name])
  end
end
