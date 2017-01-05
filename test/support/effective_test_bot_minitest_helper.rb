module EffectiveTestBotMinitestHelper
  # This is run before every test
  # def before_setup
  # end

  # This gets called after every test.  Minitest hook for plugin developers
  def before_teardown
    super

    if EffectiveTestBot.screenshots? && (@test_bot_screenshot_id || 0) > 0
      if !passed? && EffectiveTestBot.autosave_animated_gif_on_failure?
        save_test_bot_screenshot
        save_test_bot_failure_gif
      end

      if passed? && EffectiveTestBot.tour_mode?
        save_test_bot_tour_gif
      end
    end

    if passed? && !EffectiveTestBot.passed_tests[current_test_name]
      EffectiveTestBot.save_passed_test(current_test_name)
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
