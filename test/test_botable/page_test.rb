# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module PageTest
  protected

  def test_bot_page_test
    sign_in(user)

    if page_path.kind_of?(Symbol)
      visit(public_send(page_path))
    else
      visit(page_path)
    end

    assert_page_normal
    assert_no_flash_errors unless test_bot_skip?(:no_flash_errors)
  end

end
