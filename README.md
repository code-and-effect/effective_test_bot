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

## TODO

Document this gem

Minitest:

rake test TEST=test/integration/clinic_assets_test.rb

TestBot:

rake test:bot TEST=posts
rake test:bot TEST=posts#index
rake test:bot TEST=

Excepts will always work and be accounted for in test:bot
Definign TEST= works with test names 'documents#new' or 'documents' or 'something_path' but not with 'flash' assertions


    # config.except = [
    #   'flash',
    #   'users#show',
    #   'users#create_invalid' => ['path', 'page_title'],
    #   'users#create_invalid' => 'no_unpermitted_params',
    #   'report_total_allocation_index_path'
    #   'documents#destroy flash'
    # ]


require 'test_helper'

class UsersTest < ActionDispatch::IntegrationTest
  # The Create and Update action return to /members/12345 instead of /users/12345 when failing validation
  # This is a side effect of working in the same namespace as devise
  crud_test(User, User.find_by_email('admin@agilestyle.com'), except: :show, skip: {create_invalid: :path, update_invalid: :path})
end

require 'test_helper'

class SettingTest < ActionDispatch::IntegrationTest
  crud_test(Setting, User.first, only: [:new, :create])
end

require 'test_helper'

class PhysiciansTest < ActionDispatch::IntegrationTest
  page_test(:user_settings_path, User.first)
  page_test(:user_settings_path, User.first)
  page_test(:user_settings_path, User.first)
  crud_test(Physician, User.first, except: :show)
  crud_test('physicians', User.first, except: :show)

  test 'another action' do
    crud_action_test(:new, Physician, User.first)
  end
end




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
