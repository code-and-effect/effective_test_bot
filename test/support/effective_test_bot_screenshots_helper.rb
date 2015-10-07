require 'RMagick'

module EffectiveTestBotScreenshotsHelper
  include Magick

  # This gets called after every test
  # To be used by plugins NOT test developers
  def after_teardown
    super();
    return unless defined?(current_test)

    ### Here we create an animated gif out of the all collected screenshots
    Dir.mkdir('test/tour') unless File.exists?('test/tour')

    animation = ImageList.new(*Dir["tmp/test_bot/#{current_test}/*.png"])
    animation.delay = 20 # delay 1/5 of a second between images.
    animation.write("test/tour/#{current_test}.gif")
  end

  # Creates a screenshot based on the current test and the order in this test.
  def save_test_bot_screenshot
    return unless defined?(current_test)

    page.save_screenshot("tmp/test_bot/#{current_test}/#{screenshot_id}.png")
  end

  private

  # Auto increment
  def screenshot_id
    @test_bot_screenshot_id = (@test_bot_screenshot_id || 0) + 1

    if @test_bot_screenshot_id < 10
      "0#{@test_bot_screenshot_id}"
    else
      @test_bot_screenshot_id.to_s
    end
  end

end
