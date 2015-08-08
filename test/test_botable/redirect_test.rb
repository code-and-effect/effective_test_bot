# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module RedirectTest
  protected

  def test_bot_redirect_test
    test_bot_skip?
    sign_in(user)

    visit(from_path)
    assert_redirect(from_path, to_path)
    assert_page_status
    assert_page_title
    assert_no_js_errors

    #page.save_screenshot("#{from_path.parameterize}.png")
  end

end
