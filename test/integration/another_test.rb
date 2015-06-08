require "test_helper"

#class HomePageTest < Capybara::Rails::TestCase
class AnotherTest < ActionDispatch::IntegrationTest
  def page_sanity_will_be_checked
    visit root_path
    page.save_screenshot('something.png')
    page.must_have_content "Test bot home Another test spec!"
  end

  test 'okay sanity check now' do
    puts "BLAH"
    visit root_path
    page.must_have_content "Test bot TEST home Another test spec!"
  end

end
