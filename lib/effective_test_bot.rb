require 'effective_resources'
require 'effective_test_bot/engine'
require 'effective_test_bot/dsl'
require 'effective_test_bot/middleware'
require 'effective_test_bot/version'
require 'timecop'

module EffectiveTestBot
  mattr_accessor :passed_tests

  def self.config_keys
    [
      :user,
      :except, :only,
      :fail_fast,
      :form_fills,
      :screenshots, :autosave_animated_gif_on_failure,
      :tour_mode, :tour_mode_extreme,
      :animated_gif_delay, :animated_gif_background_color,
      :image_processing_class_name,
      :backtrace_lines, :silence_skipped_routes
    ]
  end

  include EffectiveGem

  # Test could be something like "crud_test", "crud_test (documents#new)", "documents", documents#new"
  # Assertion will be page_title, or flash

  def self.skip?(test, assertion = nil)
    return false if (test || assertion).blank?

    test = test.to_s
    assertion = assertion.to_s

    # If I get passed a method_name, "crud_test: (posts#create_invalid)" extract the inner test name from it
    # I dunno why this is needed really, but it might help someone one day.
    if test.include?('_test: (')  # This is how the BaseDsl test_bot_method_name formats the test names.
      left = test.index('(') || -1
      right = test.rindex(')') || (test.length+1)
      test = test[(left+1)..(right-1)]
    end

    if failed_tests_only? && test.present? && passed_tests[test]
      return true
    end

    value = "#{test} #{assertion}".strip # This is the format config.excepts is flattened into
    test_prefix = test.split('#').first

    # Excepts are defined in the app's config/initializers/effective_test_bot.rb file
    return true if excepts.any? { |except| [test, test_prefix, assertion, value].include?(except) }

    # Onlies are defined in the same config file, or on the command like rake test:bot TEST=posts#new
    # It doesn't match just 'flash' or 'page_title' assertions
    return true if onlies.present? && onlies.find { |only| test.start_with?(only) }.blank?

    false # Don't skip this test
  end

  # If you call rake test:bot TOUR=false, then disable screenshots too
  def self.screenshots?
    screenshots == true
  end

  def self.gifs?
    screenshots? && image_processing_class.present?
  end

  def self.image_processing_class
    @@image_processing_class ||= image_processing_class_name.safe_constantize
  end

  def self.autosave_animated_gif_on_failure?
    autosave_animated_gif_on_failure && gifs?
  end

  def self.fail_fast?
    if (ENV['FAIL_FAST'] || ENV['FAILFAST']).present?
      ['true', '1'].include?((ENV['FAIL_FAST'] || ENV['FAILFAST']).to_s.downcase)
    else
      fail_fast == true
    end
  end

  def self.failed_tests_only?
    if (ENV['FAILS'] || ENV['FAIL']).present?
      ['true', '1'].include?((ENV['FAILS'] || ENV['FAIL']).to_s.downcase)
    else
      false
    end
  end

  def self.tour_mode?
    if ENV['TOUR'].present?
      ENV['TOUR'].to_s != 'false'
    else
      gifs? && (tour_mode != false)
    end
  end

  # form_filler will take a screenshot after every form field is filled
  def self.tour_mode_extreme?
    if ENV['TOUR'].present?
      ['extreme', 'debug'].include?(ENV['TOUR'].to_s.downcase)
    else
      gifs? && ['extreme', 'debug'].include?(tour_mode.to_s)
    end
  end

  def self.passed_tests
    @@passed_tests ||= load_passed_tests
  end

  def self.load_passed_tests
    {}.tap do |tests|
      (File.readlines(passed_tests_filename).each { |line| tests[line.chomp] = true } rescue nil)
    end
  end

  def self.save_passed_test(name)
    return if EffectiveTestBot.passed_tests[name] == true

    EffectiveTestBot.passed_tests[name] = true

    # Make test pass directory. These can inconsistently fail when doing parallel tests
    unless Dir.exist?("#{Rails.root}/tmp")
      (Dir.mkdir("#{Rails.root}/tmp") rescue false)
    end

    unless Dir.exist?("#{Rails.root}/tmp/test_bot")
      (Dir.mkdir("#{Rails.root}/tmp/test_bot") rescue false)
    end

    File.open(passed_tests_filename, 'a') { |file| file.puts(name) }
  end

  private

  def self.onlies
    @@onlines ||= begin
      flatten_and_sort(
        if ENV['TEST_BOT_TEST'].present?
          ENV['TEST_BOT_TEST'].to_s.gsub('[', '').gsub(']', '').split(',').map { |str| str.strip }
        else
          only
        end
      )
    end
  end

  def self.excepts
    @@excepts ||= flatten_and_sort(except)
  end

    # config.except = [
    #   'assert_path',
    #   'users#show',
    #   'users#create_invalid' => ['assert_path'],
    #   'users#create_invalid' => 'assert_unpermitted_params',
    #   'report_total_allocation_index_path'
    # ]

    # We need to flatten any Hashes into
    #   'users#create_invalid' => ['assert_path', 'assert_page_title'],
    # into this
    # ['users#create_invalid assert_path'
    # 'users#create_invalid assert_page_title']

  def self.flatten_and_sort(skips)
    Array(skips).flat_map do |skip|
      case skip
      when Symbol
        skip.to_s
      when Hash
        skip.keys.product(skip.values.flatten).map { |p| p.join(' ') }
      else
        skip
      end
    end.compact.sort
  end

  def self.passed_tests_path
    "#{Rails.root}/tmp/test_bot"
  end

  def self.passed_tests_filename
    "#{passed_tests_path}/passed_tests.txt"
  end

end
