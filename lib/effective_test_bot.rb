require "effective_test_bot/engine"
require "effective_test_bot/version"

module EffectiveTestBot
  mattr_accessor :except
  mattr_accessor :only

  def self.setup
    yield self
  end

  # Test could be something like "crud_test", "crud_test (documents#new)", "documents", documents#new"
  # Assertion will be page_title, or flash

  def self.skip?(test, assertion = nil)
    # If I get passed a method_name, extract the test from it
    test = test.to_s

    if test.include?('_test: (')  # This is how the BaseDsl test_bot_method_name formats the test names.
      left = test.index('(') || -1
      right = test.rindex(')') || (test.length+1)
      test = test[(left+1)..(right-1)]
    end

    value = [test.to_s.presence, assertion.to_s.presence].compact.join(' ')
    return false if value.blank?

    if onlies.present?
      onlies.find { |only| value.start_with?(only) }.blank? # Let partial matches work
    elsif excepts.present?
      excepts.find { |except| except == value }.present?
    else
      false
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
