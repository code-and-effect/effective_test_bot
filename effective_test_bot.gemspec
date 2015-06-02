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
  s.summary     = "A shared library of rails model & capybara-based feature tests that should pass in every Rails application."
  s.description = "A shared library of rails model & capybara-based feature tests that should pass in every Rails application."
  s.licenses    = ['MIT']

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'rails'
  s.add_dependency 'rspec-rails'
  s.add_dependency 'capybara'
  s.add_dependency 'capybara-webkit'
  s.add_dependency 'capybara-screenshot'
  s.add_dependency 'shoulda-matchers'
  s.add_dependency 'guard'
  s.add_dependency 'guard-livereload'
  s.add_dependency 'guard-rspec'
end
