require "effective_test_bot/engine"
require "effective_test_bot/version"

module EffectiveTestBot
  def self.setup
    yield self
  end

end
