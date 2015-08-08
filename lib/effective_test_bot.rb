require "effective_test_bot/engine"
require "effective_test_bot/version"

module EffectiveTestBot
  mattr_accessor :except
  mattr_accessor :only

  def self.setup
    yield self
  end

  def skip?(test)
    true
  end

end
