module EffectiveTestBotMinitestHelper
  # This is run before every test
  # def before_setup
  # end

  # This gets called after every test.  Minitest hook for plugin developers
  def after_teardown
    if EffectiveTestBot.screenshots? && (@test_bot_screenshot_id || 0) > 0
      save_test_bot_failure_gif if !passed? && EffectiveTestBot.autosave_animated_gif_on_failure?
      save_test_bot_tour_gif if passed? && EffectiveTestBot.tour_mode?
    end

    if passed? && !EffectiveTestBotMinitestHelper.passed_tests[current_test_name]
      EffectiveTestBotMinitestHelper.passed_tests[current_test_name] = true
      EffectiveTestBotMinitestHelper.save_passed_tests
    end
  end

  def self.passed_tests
    @@passed_tests ||= load_passed_tests
  end

  protected

  # There are 3 different paths we're working with
  # current_test_temp_path: contains individually numbered .png screenshots produced by capybara
  # current_test_tour_path: destination for .gifs of passing tests
  # current_test_failure_path: destination for .gifs of failing tests

  def current_test_temp_path
    @_current_test_temp_path ||= "#{Rails.root}/tmp/test_bot/#{current_test_name.parameterize}"
  end

  def current_test_failure_path
    "#{Rails.root}/tmp/test_bot"
  end

  def current_test_failure_filename
    # Match Capybara-screenshots format-ish
    "#{current_test_name.parameterize}_failure_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.gif"
  end

  # Where the tour animated gif ends up
  def current_test_tour_path
    "#{Rails.root}/test/tours"
  end

  def current_test_tour_filename
    "#{current_test_name.parameterize}.gif"
  end

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

  def self.passed_tests_filename
    "#{Rails.root}/tmp/test_bot/passed_tests.txt"
  end

  def self.load_passed_tests
    {}.tap do |tests|
      (File.readlines(passed_tests_filename).each { |line| tests[line.chomp] = true } rescue nil)
    end
  end

  def self.save_passed_tests
    File.open(passed_tests_filename, 'w') do |file|
      passed_tests.each { |test_name, _| file.puts(test_name) }
    end
  end

end
