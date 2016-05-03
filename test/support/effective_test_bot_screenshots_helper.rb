require 'RMagick'

module EffectiveTestBotScreenshotsHelper
  include Magick

  # Creates a screenshot based on the current test and the order in this test.
  def save_test_bot_screenshot
    return unless EffectiveTestBot.screenshots?
    page.save_screenshot("#{current_test_temp_path}/#{current_test_screenshot_id}.png")
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
