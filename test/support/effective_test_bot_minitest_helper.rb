module EffectiveTestBotMinitestHelper
  # This is run before every test
  # def before_setup
  # end

  # This gets called after every test.  Minitest hook for plugin developers
  def after_teardown
    return unless EffectiveTestBot.screenshots? && (@test_bot_screenshot_id || 0) > 0

    if !passed? && EffectiveTestBot.autosave_animated_gif_on_failure?
      save_test_bot_failure_gif
    end

    if passed? && EffectiveTestBot.tour_mode?
      save_test_bot_tour_gif
    end
  end

  protected

  # There are 3 different paths we're working with
  # current_test_temp_path: contains individually numbered .png screenshots produced by capybara
  # current_test_tour_path: destination for .gifs of passing tests
  # current_test_failure_path: destination for .gifs of failing tests

  def current_test_temp_path
    @_current_test_temp_path ||= "#{Rails.root}/tmp/test_bot/#{current_test_name}"
  end

  def current_test_failure_path
    "#{Rails.root}/tmp/test_bot"
  end

  def current_test_failure_filename
    # Match Capybara-screenshots format-ish
    "#{current_test_name}_failure_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.gif"
  end

  # Where the tour animated gif ends up
  def current_test_tour_path
    "#{Rails.root}/test/tours"
  end

  def current_test_tour_filename
    "#{current_test_name}.gif"
  end

  def current_test_name
    @_current_test_name ||= (
      if defined?(current_test) # test_bot class level methods set this variable
        current_test
      elsif @NAME.present?  # minitest sets this variable
        @NAME
      else
        Time.now.strftime('%Y-%m-%d-%H-%M-%S') # fallback
      end.to_s.parameterize
    )
  end

end
