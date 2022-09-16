# Effective TestBot

Stop testing and start test botting.

A [minitest](https://github.com/seattlerb/minitest) library of [capybara](https://github.com/jnicklas/capybara) based Rails System Tests that should pass in every Ruby on Rails application.

Adds many additional assertions and quality of life helper functions.

Provides a curated set of minitest and capybara focused rails testing gems and a well configured `test_helper.rb` file.

Run `rails test:bot:environment` to validate your testing environment. Ensures that all fixtures and seeds are properly initialized. Makes sure database transactions and web sessions correctly reset between tests.

Adds many class and instance level 1-liners to run entire test suites and check many assertions all at once.

Autosaves an animated .gif for any failing test.

Run `rails test:bot` to automatically check every route in your application against an appropriate test suite, without writing any code. Clicks through every page, intelligently fills forms with appropriate pseudo-random input and checks for all kinds of errors and omissions.

Turn on tour mode to programatically generate an animated .gif of every workflow in your website.

Make sure everything actually works.


## effective_test_bot 1.0

This is the 1.0 series of effective_test_bot.

This requires Rails 5.1+

Please check out [Effective TestBot Capybara-Webkit branch](https://github.com/code-and-effect/effective_test_bot/tree/capybara-webkit) for more information using this gem with Capybara Webkit and Rails < 5.1.

This works with Rails 6.0.0.rc1 and parallelization.

See [effective_website](https://github.com/code-and-effect/effective_website) for a working rails website example that uses effective_test_bot.

## Getting Started

First, make sure your site is using [devise](https://github.com/plataformatec/devise) and that your application javascript includes [jQuery](http://jquery.com/) and rails' [jquery_ujs](https://github.com/rails/jquery-ujs).

```ruby
gem 'devise'
gem 'jquery-rails'
```

and in your application.js file:

```ruby
//= require jquery
//= require jquery_ujs
```

Then you're ready to install `effective_test_bot`:

```ruby
group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'effective_test_bot'

  # Optional.  Only required if you want animated gifs.
  gem 'rmagick'
end
```

Run the bundle command to install it:

```
bundle install
```

Install the configuration file:

```
rails generate effective_test_bot:install
```

The generator will run `minitest:install` if not already present and create an initializer file which describes all config options.

Fixture or seed one user. At least one user -- ideally a fully priviledged admin type user -- must be created.

(there are future plans to make this better.  Right now `rails test:bot` just runs everything as one user.  There really isn't support for 'this user should not be able to' yet.)

To create the initial user, please add it to either `test/fixtures/users.yml`, the `db/seeds.db` file or the effective_test_bot specific `test/fixtures/seeds.rb` file.

Finally, to test that your testing environment is set up correctly run and work through any issues with:

```
rails test:bot:environment
```

You now have effective_test_bot configured and you're ready to go:

```
rails test
rails test:system

rails test:bot
rails test:bot TEST=posts#index

rails test:bot:tour

rails test:bot:fails
rails test:bot:fails TOUR=true

rails test:bot:fail   # Kind of weird with parallelization
```

## How to use this gem

Effective TestBot provides 4 areas of support in writing [minitest](https://github.com/seattlerb/minitest) [capybara](https://github.com/jnicklas/capybara) tests. As a developer, use this gem to:

1.) Enjoy a whole bunch of individual assertions and quality of life helper functions.

2.) Call one-liner methods to run test suites (10-50+ assertions) against a page, or use these methods to build larger tests.

3.) Produce animated .gifs of test runs. Enable autosave_animated_gif_on_failure to help debug a tricky test, or run in tour mode and record walkthroughs of features.

4.) Apply full stack automated testing. Just run `rails test:bot` to scan every route in your application and without writing any code check every controller action with an appropriate test suite.

## Minitest Assertions

The following assertions are added for use in any integration test:

- `assert_assigns` asserts a given rails view_assigns object is present.
- `assert_assigns_errors` use after an intentionally invalid form submit to make sure your assigned rails object has errors, or a specific error.
- `assert_authorization` checks for a 403 Access Denied error.  For this to work, please add `assign_test_bot_access_denied_exception(exception) if defined?(EffectiveTestBot)` to the bottom of your ApplicationController's `rescue_from` block, after the respond_to, to generate more information.
- `assert_no_assigns_errors` should be used after any form submit to make sure your assigned rails object has no errors.  Prints out any errors if they exist.
- `assert_current_path(path)` asserts the current page path.
- `assert_email(action)` asserts an email with the given action name was sent. Also supports `assert_email(to: email)` type syntax with to, from, subject, body.
- `assert_flash`, optionally with the desired `:success`, `:error` key and/or message, makes sure the flash is set.
- `assert_jquery_ujs_disable_with` makes sure all `input[type=submit]` elements on the page have the `data-disable-with` property set.
- `assert_no_html_form_validation_errors` checks for frontend html5 errors.
- `assert_no_js_errors` checks for any javascript errors on the page.
- `assert_page_content(content)` checks that the given content is present without waiting the capybara default wait time.
- `assert_no_page_content(content)` checks that the given content is blank without waiting the capybara default wait time.
- `assert_page_status` checks for a given http status, default 200.
- `assert_page_title` makes sure there is an html `<title></title>` present.
- `assert_redirect(from_path)` optionally with to_path, makes sure the current page path is not from_path.
- `assert_signed_in` checks that the assigned `@current_user` is present.
- `assert_signed_out` checks that the assigned `@current_user` is blank.
- `assert_submit_input` makes sure there is an `input[type='submit']` present.

As well,

- `assert_page_normal` checks for general errors on the current page. Checks include `assert_page_status`, `assert_no_js_errors`, and `assert_page_title`.

## Object Extras

Includes a `stub_any_instance` helper:

```
String.stub_any_instance(:length, 42) do
  assert_equal "hello".length, 42
end
```

## Capybara Extras

The following quality of life helpers are added by this gem:

### fill_form

Finds all input, select and textarea form fields and fills them with pseudo-random but appropriate values.

Intelligently fills names, addresses, start and end dates, telephone numbers, postal and zip codes, file, price, email, numeric, password and password confirmation fields. Probably more.

Will only fill visible fields that are currently visible and not disabled.

If a selection made in one field changes the visibility/disabled of fields later in the form, those fields will be properly filled.

It clicks through bootstrap tabs and fill them nicely left-to-right, one tab at a time, and knows how to work with [cocoon](https://github.com/nathanvda/cocoon), [select2](https://select2.github.io/) and [effective_assets](https://github.com/code-and-effect/effective_assets) form fields.

You can pass a Hash of 'fills' to specify specific input values:

```ruby
# app/test/system/posts_test.rb
class PostTest < ApplicationSystemTestCase
  test 'creating a new post' do
    visit new_post_path
    fill_form(title: 'A Cool Post', 'author.last_name': 'Smith')
    submit_form
  end
end
```

And you can disable specific fields from being filled, by modifying the input html in your normal view:

```ruby
= f.input :too_complicated, 'data-test-bot-skip': true
```

Sometimes you have the requirement that inputs add upto a certain number. For example, having to provide percentages in 3-4 input fields that always add upto 100%.

You can use the html `min` and `max` properties to indicate this requirement.

The `min` and `max` html properties are considered when filling in any numeric field -- the fill value will always be within the specified range.

If there are 2 or more numeric inputs that end with the same jquery selector, the fields will be filled so that their sum will match the html `max` value.

You can scope the fill_form to a particular area of the page by using the regular `within` `do..end` block

### submit_form

Clicks the first `input[type='submit']` field (or first submit field with the given label) and submits the form.

Automatically checks for `assert_no_html5_form_validation_errors`, `assert_jquery_ujs_disable_with` and `assert_no_unpermitted_params`

```ruby
class PostTest < ApplicationSystemTestCase
  test 'creating a new post' do
    visit(new_post_path) and fill_form
    submit_form    # or submit_form('Save and Continue')
  end
end
```

### other helpers

- `as_user(user) do .. end` yields a block between `sign_in`, and `logout`.
- `clear_form` clears all form fields, probably used before `submit_novalidate_form` to test invalid form submissions.
- `click_first(label)` clicks the first link matching the given label
- `submit_novalidate_form` submits the form without client side validation, ignoring any required field requirements.
- `sign_in(user)` optionally with user, signs in via `Warden::Test::Helpers` hacky login skipping method.
- `sign_in_manually(user, password)` visits the devise `new_user_session_path` and signs in via the form.
- `sign_up` visits the devise `new_user_registration_path` and signs up as a new user.
- `synchronize!` should fix any timing issues waiting for page elements.
- `was_redirect?` returns true/false if the last time we changed pages was a 304 redirect.
- `within_if(selector, boolean) do .. end` runs the block inside capybara's `within do .. end` if boolean is true, otherwise runs the same block skipping the `within`.

## Capybara Super Extras

Running system tests is supposed to be a black-box integration testing experience. This provides a lot of benefits, but also some severe limitations.

The test web server runs in a totally separate process. It knows nothing about your application and it does not have access to any of the rails internal state. It only sees html, javascript, css and urls.

effective_test_bot fills in this knowledge gap by serializing any interesting values with a javascript payload. This gives our tests a way to peek inside the black box.

The following representations of the rails internal state are made available:

- `assigns` a Hash representation of the current page's rails `view_assigns`. Serializes any `ActiveRecord` objects, as well as any `TrueClass`, `FalseClass`, `NilClass`, `String`, `Symbol`, and `Numeric` objects. Does not serialize anything else, but sets a symbol `assigns[key] == :present_but_not_serialized`.
- `flash` a Hash representation of the current page's flash.

## Effective Test Suites

Each of the following test suites make 10-50+ assertions on a given page or controller action.  The idea is to check for every possible error or omission accross all layers of the stack.

These may be used as standalone one-liners, in the style of [shoulda-matchers](https://github.com/thoughtbot/shoulda-matchers) and as helper methods to quickly build up more advanced tests.

Each test suite has a class-level one-liner `x_test` and and one or more instance level `x_action_test` versions.

### crud_test

This test runs through the standard [CRUD](http://edgeguides.rubyonrails.org/getting_started.html) workflow of a given controller and checks that resource creation functions as expected -- that all the model, controller, views and database actually work -- and tries to enforce best practices.

There are 9 different `crud_action_test` test suites that may be run individually. The one-liner `crud_test` runs all of them.

The following instance level `crud_action_test` methods are available:

- `crud_action_test(:index)` signs in as the given user, finds or creates a resource, visits `resources_path` and checks that a collection of resources has been assigned.
- `crud_action_test(:new)` signs in as the given user, visits `new_resource_path`, and checks for a properly named form appropriate to the resource.
- `crud_action_test(:create_invalid)` signs in as the given user, visits `new_resource_path` and submits an empty form. Checks that all errors are properly assigned and makes sure a new resource was not created.
- `crud_action_test(:create_valid)` signs in as the given user, visits `new_resource_path`, and submits a valid form.  Checks for any errors and makes sure a new resource was created.
- `crud_action_test(:show)` signs in as the given user, finds or creates a resource, visits `resource_path` and checks that the resource is shown.
- `crud_action_test(:edit)` signs in as the given user, finds or creates a resource, visits `edit_resource_path` and checks that an appropriate form exists for this resource.
- `crud_action_test(:update_invalid)` signs in as the given user, finds or creates a resource, visits `edit_resource_path` and submits an empty form.  Checks that the existing resource wasn't updated and that all errors are properly assigned and displayed.
- `crud_action_test(:update_valid)` signs in as the given user, finds or creates a resource, visits `edit_resource_path` and submits a valid form. Checks for any errors and makes sure the existing resource was updated.
- `crud_action_test(:destroy)` signs in as the given user, finds or creates a resource, visits `resources_path`.  It then finds or creates a link to destroy the resource and clicks the link. Checks for any errors and makes sure the resource was deleted. If the resource `respond_to?(:archived)` it will check for archive behavior instead of delete.

Also,

- `crud_action_test(:tour)` signs in as a given user and calls all the above `crud_action_test` methods from inside one test. The animated .gif produced from this test suite records the entire process of creating, showing, editing and deleting a resource from start to finish. It makes all the same assertions as running the test suites individually.

A quick note on speed: You can speed up these test suites by fixturing, seeding or first creating an instance of the resource being tested. Any tests that need to `find_or_create_resource` check for an existing resource first, otherwise visit `new_resource_path` and submit a form to create the resource. Having a resource already created will speed things up.

There are a few variations on the one-liner method:

```ruby
class PostTest < ApplicationSystemTestCase
  # Runs all 9 crud_action tests against /posts
  crud_test(resource: Post)

  # Runs all 9 crud_action tests against /posts and use this Post's attributes when calling fill_form.
  crud_test(resource: Post.new(title: 'my first post'))

  # Runs all 9 crud_action tests against /admin/posts controller as a previously seeded or fixtured admin user
  crud_test(resource: 'admin/posts', user: User.where(admin: true).first)

  # Run only some tests
  crud_test(resource: Post, user: User.first, only: [:new, :create_valid, :create_invalid, :show, :index])

  # Run all except some tests
  crud_test(resource: Post, user: User.first, except: [:edit, :update_valid, :update_invalid])

  # Skip individual assertions
  crud_test(resource: Post, user: User.first, skip: {create_valid: :path, update_invalid: [:path, :flash]})
end
```

The individual test suites may also be used as part of a larger test:

```ruby
class PostTest < ApplicationSystemTestCase
  test 'user may only update a post once' do
    crud_action_test(test: :create_valid, resource: Post, user: User.first)
    assert_text 'successfully created post.  You may only update it once.'

    crud_action_test(test: :update_valid, resource: Post.last, user: User.first)
    assert_text 'successfully updated post.'

    crud_action_test(test: :update_valid, resource: Post.last, user: User.first, skip: [:no_assigns_errors, :updated_at])
    assert_assigns_errors(:post, 'you may no longer update this post.')
    assert_text 'you may no longer update this post.'
  end
end
```

If your resource controller passes a `crud_test` you can be certain that your user is able to correctly create, edit, display and delete a resource without encountering any application errors.

### devise_test

This test runs through the the [devise](https://github.com/plataformatec/devise) sign up, sign in, and sign in invalid workflows.

- `devise_action_test(:sign_up)` visits the devise `new_user_registration_path`, submits the sign up form and validates the `current_user`.
- `devise_action_test(:sign_in)` creates a new user and makes sure the sign in process works.
- `devise_action_test(:sign_in_invalid)` makes sure an invalid password is correctly denied.

Use as a one-liner:

```ruby
class MyApplicationTest < ApplicationSystemTestCase
  devise_test  # Runs all tests (sign_up, sign_in_valid, and sign_in_invalid)
end
```

Or each individually in part of a regular test:

```ruby
class MyApplicationTest < ApplicationSystemTestCase
  test 'user receives 10 tokens after signing up' do
    devise_action_test(test: :sign_up)
    assert_text 'Tokens: 10'
    assert_equals 10, User.last.tokens
    assert_equals 10, assigns(:current_user).tokens
  end
end
```

### member_test

This test is intended for non-CRUD actions that operate on a specific instance of a resource.

The action must be a `GET` with a required `id` value.  `member_test`-able actions appear as follows from `rake routes`:

```
unarchive_post  GET  /posts/:id/unarchive(.:format)  posts#unarchive
```

This test signs in as the given user, visits the given controller/action/page and checks `assert_page_normal` and `assert_assigns`.

Use it as a one-liner:

```ruby
class PostsTest < ApplicationSystemTestCase
  # Uses find_or_create_resource! to load a seeded resource or create a new one
  member_test(controller: 'posts', action: 'unarchive', user: User.first)

  # Run the member_test with a specific post
  member_test(controller: 'posts', action: 'unarchive', user: User.first, member: Post.find(1))
end
```

Or as part of a regular test:

```ruby
class PostsTest < ApplicationSystemTestCase
  test 'posts can be unarchived' do
    post = Post.create(title: 'first post', archived: true)

    assert Post.where(archived: false).empty?
    member_action_test(controller: 'posts', action: 'unarchive', user: User.first, member: post)
    assert Post.where(archived: false).present?
  end
end
```

### page_test

This test signs in as the given user, visits the given page and simply checks `assert_page_normal`.

Use it as a one-liner:

```ruby
class PostsTest < ApplicationSystemTestCase
  page_test(path: :posts_path, user: User.first)  # Runs the page_test test suite against posts_path as User.first
end
```

Or as part of a regular test:

```ruby
class PostsTest < ApplicationSystemTestCase
  test 'posts are displayed on the index page' do
    Post.create(title: 'first post')

    page_action_test(path: :posts_path, user: User.first)

    assert page.current_path, '/posts'
    assert_text 'first post'
  end
end
```

### redirect_test

This test signs in as the given user, visits the given page then checks `assert_redirect(from_path, to_path)` and `assert_page_normal`.

Use it as a one-liner:

```ruby
class PostsTest < ApplicationSystemTestCase
  # Visits /blog and tests that it redirects to a working /posts page
  redirect_test(from: '/blog', to: '/posts', user: User.first)
end
```

Or as part of a regular test:

```ruby
class PostsTest < ApplicationSystemTestCase
  test 'visiting blog redirects to posts' do
    Post.create(title: 'first post')
    redirect_action_test(from: '/blog', to: '/posts', user: User.first)
    assert_text 'first post'
  end
end
```

### wizard_test

This test signs in as the given user, visits the given initial page and continually runs `fill_form`, `submit_form` and `assert_page_normal` up until the given final page, or until no more `input[type=submit]` are present.

It tests any number of steps in a wizard, multi-step form, or inter-connected series of pages.

As well, in the `wizard_action_test`, each page is yielded to the calling method.

Use it as a one-liner:

```ruby
class PostsTest < ApplicationSystemTestCase
  wizard_test(from: '/build_post/step1', to: '/build_post/step5', user: User.first)
end
```

Or as part of a regular test:

```ruby
class PostsTest < ApplicationSystemTestCase
  test 'building a post in 5 steps' do
    wizard_action_test(from: '/build_post/step1', to: '/build_post/step5', user: User.first) do
      if page.current_path.end_with?('step4')
        assert_text 'your post is ready but must first be approved by an admin.'
      end
    end
  end
end
```

## Skipping individual assertions or test suites

Each of the test suites checks a page or pages for some expected behaviour.  Sometimes a developer has a good reason for deviating from what is expected and it's frustrating when just one assertion in a test suite fails.

So, almost every individual assertion made by these test suites is skippable.

When an assertion fails, the output will look something like:

```
crud_test: (users#update_invalid)                               FAIL (3.74s)

Minitest::Assertion: (current_path) Expected current_path to match resource #update path.
  Expected: "/users/1"
  Actual: "/members/1"
  /Users/matt/Sites/effective_test_bot/test/test_botable/crud_test.rb:155:in `test_bot_update_invalid_test'
```

Here, the `(current_path)` is the name of the specific test bot assertion that failed.

The expectation is that when submitting an invalid form at `/users/1/edit` we should be returned to the update action url `/users/1`, but in this totally reasonable but not-standard case we are redirected to `/members/1` instead.

You can skip this assertion by adding it to the `app/config/initializers/effective_test_bot.rb` file:

```ruby
EffectiveTestBot.setup do |config|
  config.except = [
    'users#create_invalid current_path',  # Skips the current_path assertion for just the users#create_invalid test
    'current_path',                       # Skips the current_path assertion entirely in all tests
    'users#create_invalid'                # Skips the entire users#create_invalid test
  ]
end
```

There is support for skipping individual assertions, entire tests, or a combination of both.

Please see the installed `effective_test_bot.rb` initializer file for a full description of all options.

## Testing the test environment

Unfortunately, with the current day ruby on rails ecosystem, simply getting a testing environment setup correctly is a non-trivial endeavor filled with gotchas and many things that can go wrong.

User sessions need to properly reset and database transactions must be correctly rolled back between tests. Seeds and fixtures that were once valid may become invalid as the application changes. Database migrations must stay up to date. Capybara needs to query your app with a single shared connection or weird things start happening.

Included with this gem is the `rails generate effective_test_bot:install` that does its best to provide a known-good set of configuration files that initialize all required testing gems. However, every developer's machine is different, and there are just too many points of failure. Everyone's `test/test_helper.rb` will be slightly different.

Run `rails test:bot:environment` to check that capybara is doing the right thing, everything is reset properly between test runs, an initial user record exists, all seeded and fixtured data is valid, devise works and rails' jquery-ujs is present.

If all environment tests pass, you will have a great experience with automated testing.

## Automated full stack testing

One of the main goals of `effective_test_bot` is to increase the speed at which tests can be written in any ruby on rails application. Well, there's no faster way of writing tests than by not writing them at all.

Run `rails test:bot` to scan every route defined in `routes.rb` and run an appropriate test suite.

You can configure test bot to skip individual tests or assertions, tweak screenshot behaviour and toggle tour mode via the `config/initializers/effective_test_bot.rb` file.  As well, there are a few command line options available.

These are some quick ways to customize test bot's behaviour:

```
# Scan every route in the application as per config/initializers/effective_test_bot.rb
rails test:bot

# Test a specific controller (any routes matching posts)
rails test:bot TEST=posts

# Test a specific controller and action
rails test:bot TEST=posts#index

# Only runs previously failed tests
rails test:bot:fails

# Only runs failed tests and stops after first failure
rails test:bot:fails

# Clobber (delete) all screenshots and fails
rails test:bot:clobber
```

## Animated gifs and screenshots

Call `save_test_bot_screenshot` from within any test to take a screenshot of the current page. If an animated .gif is produced at the end of the test -- either from autosave_animated_gif_on_failure or tour mode -- this screenshot will be used as one of the frames in the animation.

This method is already called by `fill_form` and `submit_form`.

To disable taking screenshots entirely set `config.screenshots = false` in the `config/initializers/effective_test_bot.rb` initializer file.

You must have `gem 'rmagick'` installed to use animated gifs.

### Tour mode

When running in tour mode, an animated .gif image file, a "tour", will be created for all successful tests.

This feature is slow, increasing the runtime of each test by almost 30%, but it's also really cool.

You can run test bot in tour mode by setting `config.tour_mode = true` in the `config/initializers/effective_test_bot.rb` file or by running any variation of the following rake tasks:

```
# Run test:bot in tour mode, saving an animated .gif for all successful tests
rails test:bot:tour
rails test:bot TOUR=true

# Also prints the animated .gif file path to stdout
rails test:bot:tourv
rails test:bot TOUR=verbose

# Makes a whole bunch of extra screenshots when filling out forms
rails test:bot TOUR=extreme

# Runs in tour mode and tests only a specific controller or action
rails test:bot:tour TEST=posts
rails test:bot:tour TEST=posts#index
```

To print out the file location of all tour files, run the following:

```
# Prints out all animated .gif file locations
rails test:bot:tours

# Prints out any animated .gif files locations with a file name matching posts
rails test:bot:tours TEST=posts
```

To delete all tour and autosave on failure animated .gifs, run the following:

```
# Deletes all tour and failure animated .gifs
rails test:bot:clobber
```

As well, to enable tour mode when running the standard `rails test`:

```
# Runs all regular minitest tests with tour mode enabled
rails test:tour
rails test:tourv
```

### Fail fast

Set `config.fail_fast = true` to exit immediately if there is a test failure.

Or, override the config setting by running the following:

```
rails test:bot FAILFAST=true
```

This functionality is provided thanks to [minitest-fail-fast](https://github.com/teoljungberg/minitest-fail-fast/)

It's kind of busted with parallelization but mostly works.

### Failed tests only

Skip any previously passed tests by running the following:

```
rails test:bot:fails
```

or

```
rails test:bot FAILS=true
```

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
