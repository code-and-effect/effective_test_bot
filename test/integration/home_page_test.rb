require "test_helper"

#class HomePageTest < Capybara::Rails::TestCase
class HomePageTest < ActionDispatch::IntegrationTest
  test "sanity" do
    visit root_path
    page.save_screenshot('something.png')
    page.must_have_content "Test bot home page spec!"
  end

end
