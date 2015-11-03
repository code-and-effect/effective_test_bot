# Effective TestBot

Stop testing and start test botting.

A minitest library of capybara-webkit based feature tests that should pass in every Ruby on Rails application.

Adds many additional minitest assertions and capybara quality of life helper functions.

Provides a curated set of minitest/capybara/rails testing gems and a well configured `test_helper.rb` minitest file.

Includes a rake task to validate your testing environment.

Ensures that all fixtures and seeds are properly initialized.  Makes sure database transactions and web sessions correctly reset between tests.

Provides a DSL of class and instance level 1-liners that run entire test suites, checking many assertions all at once.

Autosaves an animated gif for any failing test.

Run `rake test:bot` to automatically check every route in your application against an appropriate test suite, without writing any code.

Automatically fills forms with appropriate pseudo-random input, and checks for all kinds of errors and omissions along the way.

Turn on tour mode to automatically generate animated gifs of every part of your website.

Makes sure everything actually works.

## Getting Started

Make sure your site is using [devise](https://github.com/plataformatec/devise) and that your application javascript includes [jQuery](http://jquery.com/) and rails' [jquery_ujs](https://github.com/rails/jquery-ujs).

```ruby
group :test do
  gem 'effective_test_bot'
end
```

Run the bundle command to install it:

```console
bundle install
```

Install the configuration file:

```console
rails generate effective_test_bot:install
```

The generator will run `minitest:install` if minitest is not already present and create an initializer file which describes all configuration options.

Fixture or seed one user:

effective_test_bot requires that at least one user -- ideally a fully priviledged admin type user -- be available in the testing environment.

* There are future plans to make this better.  Right now `rake test:bot` just runs everything as one user.  There really isn't support for 'this user should not be able to'. yet.

As per the `test/test_helper.rb` default file, when minitest and/or effective_test_bot starts, following tasks are run:

```console
# Rails default task, load fixtures from test/fixtures/*.yml (including users.yml if it exists)
rake db:fixtures:load

# Rails default task, loads db/seeds.rb
rake db:seed

# Added by effective_test_bot.  loads test/fixtures/seeds.rb. 'cause screw yaml.
rake test:load_fixture_seeds
```

Your initial user may be created by any of the above 3 tasks.

Test that your testing environment is set up correctly:

Run `rake test:bot:environment` and make sure all the tests pass.

You now have effective_test_bot configured and you're ready to go.

# How to use this gem

Effective TestBot is a 3-layered cake of testing deliciousness.

The bottom layer consists of advanced individual minitest assertions and capybara quality of life helper functions.

The middle layer is a meta testing DSL -- 1-liners for you to use in your regular minitest tests that run entire test suites (10-50+ assertions) against a page or controller.

The final layer builds on the bottom two, run `rake test:bot` to scan every route in your application and choose an appropriate test suite to run.

## Minitest Assertions

The following assertions are added for use in any minitest & capybara integration test:

- `assert_signed_in` visits the devise `new_user_session_path` and checks for the `devise.failure.already_authenticated` content
- `assert_signed_out` visits the devise `new_user_session_path` and checks for absense of the `devise.failure.already_authenticated` content
- `assert_page_title` makes sure there is an html <title></title> present
- `assert_submit_input` makes sure there is an input[type='submit'] present
- `assert_page_status` checks for a given http status, default 200.
- `assert_current_path(path)` asserts the current page path
- `assert_redirect(from_path)` optionally with to_path, makes sure the current page path is not from_path
- `assert_no_js_errors` - checks for any javascript errors on the page
- `assert_no_unpermitted_params` makes sure the last submitted form did not include any unpermitted params and prints out any unpermitted params that do exist.
- `assert_no_exceptions` checks for any exceptions in the last page request and gives a stacktrace if there was
- `assert_no_html_form_validation_errors` checks for frontend html5 errors
- `assert_jquery_ujs_disable_with` makes sure all input[type=submit] elements on the page have the data-disable-with property set
- `assert_flash` optionally with the desired :success, :error key and/or message, makes sure the flash is set
- `assert_assigns` asserts a given rails view_assigns object is present
- `assert_no_assigns_errors` use after a form submit to make sure your assigned rails object has no errors.  Prints out any errors if they exist.
- `assert_assigns_errors` use after an intentionally invalid form submit to make sure your assigned rails object has errors, or a specific error.

## Capybara Extras

The following quality of life helpers are added for use in any minitest & capybara integration test:

### fill_form

Finds all the input, select and textarea form fields on the current page and fills them with pseudo-random appropriate values.

Detects names, addresses, start and end dates, telephone numbers, postal and zip codes, file, price, email, numeric, password and password confirmation fields. Probably more.

Will only fill visible fields that are currently visible and not disabled.

If a selection made in one field changes the visibility/disabled of fields later in the form, those fields will be properly filled.

It works with the [cocoon](https://github.com/nathanvda/cocoon), [select2](https://select2.github.io/) and [effective_assets](https://github.com/code-and-effect/effective_assets) gems.

It will click through bootstrap tabs and fill them left-to-right one tab at a time.

You can pass a Hash of 'fills' to specify specific input values:

```ruby
require 'test_helper'

class PostTest < ActionDispatch::IntegrationTest
  visit new_post_path
  fill_form(:title => 'A Cool Post', 'author.last_name' => 'Smith')
  submit_form
end
```

And you can disable specific fields from being filled, by modifying the input html in your normal view:

```ruby
= f.input :too_complicated, 'data-test-bot-skip' => true

Sometimes you have the requirement that inputs add upto a certain number.  For example, having to provide percentages in 3-4 input fields that always add upto 100%.

You can use the html `min` and `max` properties to indicate this requirement.

The `min` and `max` html properties are considered when filling in any numeric field -- the fill value will always be within the specified range.

If there are 2 or more numeric inputs that end with the same jquery selector, the fields will be filled so that their sum will match the html `max` value.

You can scope the fill_form to a particular area of the page by using the regular capybara `within` `do..end` block

### submit_form

As well as just click on the input[type='submit'] button (or optional label), this helper also checks:
- `assert_no_html5_form_validation_errors`
- `assert_jquery_ujs_disable_with`
- `assert_no_unpermitted_params`

### other helpers

- `submit_novalidate_form` will use javascript to disable all required fields, and submit a form without client side validation.
- `clear_form` clears all form fields, probably used before `submit_novalidate_form` to test invalid form submissions.
- `sign_in(user)` optionally with user, signs in via `Warden::Test::Helpers` hacky login skipping method.
- `sign_in_manually(user, password)` visits the devise `new_user_session_path` and signs in via the form
- `sign_up` visits the devise `new_user_registration_path` and signs up as a new user.
- `as_user(user) do .. end` yields a block between `sign_in`, and `logout`
- `synchronize!` should fix any timing issues waiting for capybara elements
- `was_redirect?` returns true/false if the last time we changed pages was a 304 redirect.
- `was_download?` if clicking a link returned a file of any type rather than a page change.

## Capybara Super Extras

So the problem with running integration tests with capybara-webkit is that it's a real full black-box integration test.

Capybara runs in a totally separate process.  It knows nothing about your rails app.  You can't get access to any of the rails internal state. All you can test is html, javascript and urls. That really sucks.

effective_test_bot mixes in a rails controller include and does a bit of http header hackery to make available to capybara the internal rails state values that are just so handy.

The following are refreshed on each page change, and are available to check anywhere in your tests.

- `flash` a Hash representation of the current page's flash
- `assigns` a Hash representation of the current page's rails `view_assigns`. Serializes any ActiveRecord objects, as well as any TrueClass, FalseClass, NilClass, String, Symbol, Numeric objects.  Does not serialize anything else, but sets a symbol `assigns[key] == :present_but_not_serialized`.
- `exceptions` an Array with the exception message and a stacktrace.
- `unpermitted_params` an Array of any unpermitted paramaters that were encountered by the last request

- `save_test_bot_screenshot` saves a screenshot of the current page to be added to the current test's animated gif (see screenshots and tour mode below).

## Test Bot DSL Methods

All of the following DSL methods use the assertions and capybara extras to build an entire test suite that runs against a given page or controller action.

Right now the `crud_test` method is by far the most mature, with the other methods having had less development time.

Each DSL method has a class level `x_test` and an instance level `x_action_test` version of each.

```ruby
require 'test_helper'

class PostsTest < ActionDispatch::IntegrationTest
  page_test(:posts_path, User.first)  # Runs the page_test test suite against posts_path (class level) as User.first

  # Does the same thing.
  # Runs the page_test suite against posts_path (instance level) as User.first
  test 'my posts test' do
    page_action_test(:posts_path, User.first)
  end
end

Each of these DSL test suite methods are designed to assert an expected standard rails behaviour.

But sometimes a developer has a good reason for deviating from what is considered standard; therefore, each individual assertion is skippable.

When an assertion fails, the minitest output will look something like:

TODO users (current_path) example. zzz.

The `(current_path)` is the name of the specific assertion that failed.

The expectation is that submitting a form on `/users/edit/123` will take you to the update action which should be on `/users/123`, but in this case we redirect to `/members` instead.

You can skip this specific assertion by adding it to the `app/config/initializers/effective_test_bot.rb` file:

```ruby
EffectiveTestBot.setup do |config|
  config.except = [
    'users#create_invalid path',  # Skips the path assertion for just the users#create_invalid test
    'path'                        # Skips the path assertion entirely in all tests
  ]
end
```

Please see the installed effective_test_bot.rb initializer file for a full description of all options.

### crud_test



####################################


Test Bot DSL Methods
  - one-liners that run entire test suites
  - class level and instance level version of each
  - appropriately runs all the assertions above and more
  - every individual assertion is skippable. sometimes theres a good reason to deviate from rails default expectations

  - crud_test
    - tests all CRUD actions (7 actions in 9 tests)
      - index, new, create_invalid, create_valid, show, edit, update_invalid, update_valid, delete
    - or call the tour variant for better animated giffage
      - just runs all these tests one after another
      - generates an animated gif of an entire part/feature on your website. 1-liner.
    - skip specific actions
    - understands archived and delete
  - devise_test
    - sign_up_test
    - sign_in_valid_test
    - sign_ip_invalid_test
  - page_test
  - member_test
  - redirect_test
  - wizard_test

Automated testing / Rake tasks
  - just runs everything listed above all at once automatically on every route
  - how the test keys and assertion keys work
  - how to skip individual actions or assertions

  - rake test:bot:environment # 1-time prove my environment is set up correctly
  - rake test:bot
  - rake test:bot TEST=documents#index
  - rake test:bot:tour  # Run with tour mode enabled
  - rake test:bot:tourv # verbose
  - rake test:bot:tours # list existing tours
  - rake test:bot:purge # Delete all screenshots
  - rake load_fixture_seeds # Runs test/fixtures/seeds.rb 'cause screw yaml

Screenshots and Animated Gifs
  - autosave animated gif on failure
  - tour mode
    - automatically creates an animated gif for every workflow in your application


First time set up Initial Environment Requirements
  - One of the pains in the butt about unix philosophy is you gotta use so many gems to get everything you want
  - So here I maintain a curated list of gems that I like to use for my minitest testing
    - capybara_webkit
    - shoulda
    - capybara-screenshot
    - slow_finder_errors
    - devise and warden test helpers
    - minitest_reporters
    - probably add more in the future. guard.
  - test_helper.rb
  - seeds and fixtures
  - test_bot_fixtures
  - requires at least 1 user is seeded
  - requires jquery and rails_ujs
  - Kind of requires Devise
  - Along with this, I have a script to test the minitest environment itself, ensuring
  - databases, and capybara sessions are transactional and properly reset between tests.


Testing Philosophy
  - feature tests and black box testing
  - minitest and capybara-webkit
  - recordable, repeatable, automatable
  - capybara limitations and how test_bot rails integrations improve on those
    - assigns, assigns errors, flash, exceptions, permitted_params

Licence

Contributing



Run `rake test:bot:environment` once to ensure your minitest environment is set up properly.

Run `rake test:bot` to automatically check every route in your application for all kinds of errors.

Run `rake test:bot:tour` to also record an animated gif for each controller action.

Includes all kinds of extra minitest assertions

Adds all kinds of extra assertions to minitest, and allows you to run entire test suites as a one-liner.


Automatically checks every route in your application for all kinds of errors, including:

Record animated gifs of your controller actions with only 1 or 2 lines of code.



Test your controller actions with an entire test suite in only a few lines.




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
bundle exec rake test:bot:environment
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


, input_html: {'data-test-bot-skip': true}




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



THIS IS A BLOG POST BASICALLY
## Testing Philosophy







So much of an average Ruby on Rails application is organized around CRUD, a lot of the tests


It takes non-zero time, most of the tests are just boilerplate,
and it's far too ownerous to consider every little

The guiding principle behind effective_test_bot is that it takes too long to write tests.


The guiding principle behind effective_test_bot is that writing tests sucks.

(warning: incoming nerd rant)

Unit tests are necessary.  You gotta test anything reasonably complex being done by your models.

And yea, it's best to do those tests in isolation.

Outside of that, full stack testing is the only worthwhile endeavour.

Writing controller tests, view tests and the like is just a waste of time:
  - They don't protect you against changes in your application
  - They only test what you set them up to test.
  - They overlook all kinds of simple human error like adding a form field to an existing form, but forgetting to add it to unpermitted params
  - Your existing test doesn't pass that new value, so it still passes.  No problem right?
  - They will render properly with your fixtured data, but what about a random faceroll of the keyboard?

Ontop of that, no one writes tests that consistently check all the little things:
  - Page titles, unpermitted params, flashes, data-disable-with, no javascript errors, no html5 validation errors, etc.



  Do you update your tests everytime you add an extra

They don't really protect you against changes in your application.

They test what you set them up to test, which is usually quite different than a user actually clicking through your application.

They overlook every day things like adding a form field to an existing form, but forgetting to add it to the unpermitted params.

Your unchanged controller test still passes, no problem right?

Your view may render properly with some fixtured data, but will it handle 5000 monkeys all throwing input at it?
