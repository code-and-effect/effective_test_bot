module EffectiveTestBotMinitestHelper
  # This is run before every test
  # def before_setup
  # end

  # This gets called after every test.  Minitest hook for plugin developers
  def before_teardown
    super

    if passed?
      EffectiveTestBot.save_passed_test(current_test_name)
      save_test_bot_tour_gif if EffectiveTestBot.tour_mode?
    end

    if !passed?
      save_test_bot_failure_gif if EffectiveTestBot.autosave_animated_gif_on_failure?
    end

  end

  protected

  def current_test_name
    @_current_test_name ||= (
      if defined?(current_test) # test_bot class level methods set this variable
        current_test
      elsif @NAME.present?  # minitest sets this variable
        @NAME
      else
        Time.now.strftime('%Y-%m-%d-%H-%M-%S') # fallback
      end.to_s
    )
  end

end
