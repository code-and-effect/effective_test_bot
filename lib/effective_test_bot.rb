require "effective_test_bot/engine"
require "effective_test_bot/version"

require "effective_test_bot/command"
require "effective_test_bot/worker"

module EffectiveTestBot
  def self.setup
    yield self
  end

end
