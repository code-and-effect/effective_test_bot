$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'effective_test_bot/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'effective_test_bot'
  s.version     = EffectiveTestBot::VERSION
  s.email       = ['info@codeandeffect.com']
  s.authors     = ['Code and Effect']
  s.homepage    = 'https://github.com/code-and-effect/effective_test_bot'
  s.summary     = 'A shared library of rails model & system tests that should pass in every Rails application.'
  s.description = 'A shared library of rails model & system tests that should pass in every Rails application.'
  s.licenses    = ['MIT']

  s.files = Dir['{app,config,lib,test}/**/*'] + ['MIT-LICENSE', 'README.md']

  s.add_dependency 'rails', ['>= 5.2']
  s.add_dependency 'effective_resources'
  s.add_dependency 'rmagick'
  s.add_dependency 'faker'

  # Match Rails 5.2 new Gemfile
  s.add_dependency 'capybara', '>= 2.15', '< 4.0'
  s.add_dependency 'capybara-webkit'
  s.add_dependency 'minitest-reporters'
  s.add_dependency 'minitest-fail-fast'
end
