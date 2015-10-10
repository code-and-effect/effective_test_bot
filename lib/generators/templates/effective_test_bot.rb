# EffectiveTestBot Rails Engine

if Rails.env.test?
  EffectiveTestBot.setup do |config|

    # Exclude the following tests or assertions from being run.
    # config.except = [
    #   'widgets'
    #   'posts#create_invalid'
    #   'posts#index page_title'
    #   'no_unpermitted_params'
    # ]

    # Run only the following tests.  Doesn't work with individual assertions>
    # config.only = [
    #   'posts', 'events#index'
    # ]

    # Should capybara generate a series of *.png screenshots as it goes through the test?
    # Disabling screenshots will also disable animated_gifs and touring
    config.screenshots = true

    # Save on failure to /tmp/ directory
    config.autosave_animated_gif_on_failure = true

    # Take the tour!
    # Generate an animated gif for each test
    # Saved to an appropriate /test/tour/* directory
    # You can override this default by setting an ENV
    # `rake test:bot TOUR=true`
    config.tour_mode = false

  end
end
