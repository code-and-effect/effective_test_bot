require 'test_helper'

module TestBot
  class HomePageTest < ActionDispatch::IntegrationTest
    test 'home page loads successfully' do
      visit root_path
      assert_equal page.status_code, 200
    end
  end
end
