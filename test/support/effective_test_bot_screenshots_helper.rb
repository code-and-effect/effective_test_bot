require 'RMagick'

module EffectiveTestBotScreenshotsHelper
  include Magick

  # Creates a screenshot based on the current test and the order in this test.
  def save_test_bot_screenshot
    return unless EffectiveTestBot.screenshots? && defined?(current_test)

    full_path = current_test_temp_path + "/#{current_test_screenshot_id}.png"
    page.save_screenshot(full_path)
  end

  # This is run before every test
  # def before_setup
  #   super
  #   return unless (EffectiveTestBot.screenshots? && defined?(current_test))
  # end

  # This gets called after every test.  Minitest hook for plugin developers
  def after_teardown
    super
    return unless EffectiveTestBot.screenshots? && defined?(current_test) && (@test_bot_screenshot_id || 0) > 0

    if !passed? && EffectiveTestBot.autosave_animated_gif_on_failure?
      save_test_bot_failure_gif
    end

    if passed? && EffectiveTestBot.tour_mode?
      save_test_bot_tour_gif
    end
  end

  def save_test_bot_failure_gif
    Dir.mkdir(current_test_failure_path) unless File.exists?(current_test_failure_path)
    full_path = (current_test_failure_path + '/' + current_test_failure_filename)

    save_test_bot_gif(full_path)
    puts_yellow("    Animated .gif: #{full_path}")
  end

  def save_test_bot_tour_gif
    Dir.mkdir(current_test_tour_path) unless File.exists?(current_test_tour_path)
    full_path = (current_test_tour_path + '/' + current_test_tour_filename)

    save_test_bot_gif(full_path)
    puts_green("    Tour .gif: #{full_path}") if EffectiveTestBot.tour_mode_verbose?
  end

  def without_screenshots(&block)
    original = EffectiveTestBot.screenshots

    EffectiveTestBot.screenshots = false
    yield
    EffectiveTestBot.screenshots = original
  end

  protected

  def save_test_bot_gif(full_path)

    png_images = @test_bot_screenshot_id.times.map do |x|
      current_test_temp_path + '/' + format_screenshot_id(x+1) + '.png'
    end

    images = Magick::ImageList.new(*png_images)

    # Get max dimensions.
    dimensions = {width: 0, height: 0}
    images.each do |image|
      dimensions[:width] = [image.columns, dimensions[:width]].max
      dimensions[:height] = [image.rows, dimensions[:height]].max
    end

    # Create a final ImageList
    animation = Magick::ImageList.new()

    # Remove the PNG's alpha channel, 'cause .gifs dont support it
    # Extend the bottom/right of each image to extend upto dimension
    delay = [(EffectiveTestBot.animated_gif_delay.to_i rescue 0), 10].max
    last_image = images.last

    images.each do |image|
      image.alpha Magick::DeactivateAlphaChannel
      image.delay = (image == last_image) ? (delay * 4) : delay
      image.background_color = EffectiveTestBot.animated_gif_background_color

      animation << image.extent(dimensions[:width], dimensions[:height])
    end

    # Run it through https://rmagick.github.io/ilist.html#optimize_layers
    animation = animation.optimize_layers(Magick::OptimizeLayer)

    # Write the final animated gif
    animation.write(full_path)
  end

  # There are 3 different paths we're working with
  # current_test_temp_path: contains individually numbered .png screenshots produced by capybara
  # current_test_tour_path: destination for .gifs of passing tests
  # current_test_failure_path: destination for .gifs of failing tests

  def current_test_temp_path
    @_current_test_temp_path ||= "#{Rails.root}/tmp/test_bot/#{current_test || 'none'}"
  end

  def current_test_failure_path
    "#{Rails.root}/tmp/test_bot"
  end

  def current_test_failure_filename
    # Match Capybara-screenshots format-ish
    "#{current_test}_failure_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.gif"
  end

  # Where the tour animated gif ends up
  def current_test_tour_path
    "#{Rails.root}/test/tours"
  end

  def current_test_tour_filename
    "#{current_test}.gif"
  end

  private

  # Auto incrementing counter
  # The very first screenshot will be 01.png (tmp/test_bot/posts#new/01.png)
  def current_test_screenshot_id
    @test_bot_screenshot_id = (@test_bot_screenshot_id || 0) + 1
    format_screenshot_id(@test_bot_screenshot_id)
  end

  def format_screenshot_id(number)
    number < 10 ? "0#{number}" : number.to_s
  end

  def puts_yellow(text)
    puts "\e[33m#{text}\e[0m" # 33 is yellow
  end

  def puts_green(text)
    puts "\e[32m#{text}\e[0m" # 32 is green
  end
end
