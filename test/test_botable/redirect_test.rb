# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module RedirectTest
  protected

  def test_bot_redirect_test
    sign_in(user) and visit(from)

    assert_redirect(from, to)
    assert_page_normal
    assert_no_flash_errors unless test_bot_skip?(:no_flash_errors)
  end

end
