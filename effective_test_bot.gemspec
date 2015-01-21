$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "effective_test_bot/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "effective_test_bot"
  s.version     = EffectiveTestBot::VERSION
  s.email       = ["info@codeandeffect.com"]
  s.authors     = ["Code and Effect"]
  s.homepage    = "https://github.com/code-and-effect/effective_test_bot"
  s.summary     = ""
  s.description = ""
  s.licenses    = ['MIT']

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", [">= 3.2.0"]

  # s.add_development_dependency "rspec-rails"
  # s.add_development_dependency "sqlite3"
end
