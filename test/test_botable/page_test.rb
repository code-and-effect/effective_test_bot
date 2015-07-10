module PageTest
  private

  def test_bot_page
    sign_in(user) and visit(send(page_path))

    assert_page_status
    assert_page_title
    assert_no_js_errors

    page.save_screenshot("#{page_path}.png")
  end

end
