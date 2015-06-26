# Effective TestBot

A shared library of rails model & capybara-based feature tests that should pass in every Rails application.

Also provides a one-liner installation & configuration of minitest and capybara test environment.

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

The above command will first invoke the default `minitest` installation tasks, if they haven't already been run.

It will then copy the packaged `test_helper.rb` that matches this gem author's opinionated testing environment.

Run the test suite with:

```ruby
bundle exec rake test:bot
```

You should now see multiple -- hopefully passing -- tests that you didn't write!



rake test TEST=test/integration/clinic_assets_test.rb


## Fixtures

TODO

users.yml:

```yaml
normal:
  email: 'normal@agilestyle.com'
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>
```


## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

Code and Effect is the product arm of [AgileStyle](http://www.agilestyle.com/), an Edmonton-based shop that specializes in building custom web applications with Ruby on Rails.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
