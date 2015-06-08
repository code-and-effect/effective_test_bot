require "test_helper"

class HomePageTest < Capybara::Rails::TestCase
  test "sanity" do
    visit root_path
    assert_content page, "Test bot home page spec!"
  end

end
