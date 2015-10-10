require "effective_test_bot/engine"
require "effective_test_bot/version"

module EffectiveTestBot
  mattr_accessor :except
  mattr_accessor :only
  mattr_accessor :screenshots
  mattr_accessor :autosave_animated_gif_on_failure
  mattr_accessor :tour_mode

  def self.setup
    yield self
  end

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

    value = "#{test} #{assertion}".strip # This is the format config.excepts is flattened into

    # Excepts are defined in the app's config/initializers/effective_test_bot.rb file
    return true if excepts.any? { |except| [test, assertion, value].include?(except) }

    # Onlies are defined in the same config file, or on the command like rake test:bot TEST=posts#new
    # It doesn't match just 'flash' or 'page_title' assertions
    return true if onlies.present? && onlies.find { |only| test.start_with?(only) }.blank?

    false # Don't skip this test
  end

  # If you call rake test:bot TOUR=false, then disable screenshots too
  def self.screenshots?
    screenshots == true
  end

  def self.autosave_animated_gif_on_failure?
    screenshots && autosave_animated_gif_on_failure
  end

  def self.tour_mode?
    if ENV['TOUR'].present?
      ['true', 'verbose', 'debug'].include?(ENV['TOUR'].to_s.downcase)
    else
      screenshots && (tour_mode != false)
    end
  end

  def self.tour_mode_verbose?
    if ENV['TOUR'].present?
      ['verbose', 'debug'].include?(ENV['TOUR'].to_s.downcase)
    else
      screenshots && ['verbose', 'debug'].include?(tour_mode.to_s)
    end
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

end
