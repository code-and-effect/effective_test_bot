$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'effective_test_bot/version'

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

  s.files = Dir["{app,config,db,lib,spec,test}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency 'rails'
  s.add_dependency 'minitest'
  s.add_dependency 'minitest-rails'
  s.add_dependency 'minitest-capybara'
  s.add_dependency 'minitest-fail-fast'
  s.add_dependency 'minitest-rails-capybara'
  s.add_dependency 'minitest-reporters'
  s.add_dependency 'capybara'
  s.add_dependency 'capybara-webkit', '>= 1.6.0'
  s.add_dependency 'capybara-screenshot'
  s.add_dependency 'capybara-slow_finder_errors'
  s.add_dependency 'database_cleaner'
  s.add_dependency 'shoulda'
  s.add_dependency 'shoulda-matchers'
  s.add_dependency 'rmagick'
  s.add_dependency 'faker'
end
