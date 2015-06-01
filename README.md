# Effective TestBot

A shared library of rails model & capybara-based feature tests that should pass in every Rails application.

Also provides a one-liner installation & configuration of rspec-rails, guard, and capybara test environment.

Rails 3.2.x and 4.x


## Getting Started

Add to your Gemfile:

```ruby
gem 'effective_test_bot'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_test_bot:install
```

The above command will first invoke the default `rspec-rails` and `guard` installation tasks, if they haven't already been run.

It will then copy the packaged `spec_helper.rb`, `rails_helper.rb` and other rspec/testing configuration files that match this gem author's opinionated testing environment.

Run the test suite with either rspec, or guard, or as you normally would:

```ruby
bundle exec guard # (then press ENTER)
```

or

```ruby
bundle exec rspec
```

You should now see multiple -- hopefully passing -- tests that you didn't write!


### Existing rspec installation

If you already have an existing rspec installation that works with `capybara` and `capybara-webkit`, you will only need to add this one line to your `spec/spec_helper.rb`:

```
RSpec.configure do |config|
  config.files_or_directories_to_run = ['spec', '../effective_test_bot/spec']
end
```


## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

Code and Effect is the product arm of [AgileStyle](http://www.agilestyle.com/), an Edmonton-based shop that specializes in building custom web applications with Ruby on Rails.


## Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

