# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module PageTest
  protected

  def test_bot_page_test
    sign_in(user) and visit(public_send(page_path))

    assert_page_status
    assert_page_title
    assert_no_js_errors



    page.save_screenshot("#{page_path}.png")
  end

end
