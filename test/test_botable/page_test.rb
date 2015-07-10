module PageTest
  private

  def page_test
    sign_in(user) and visit(send(page_path))

    assert_page_status
    assert_page_title
    assert_no_js_errors

    page.save_screenshot("#{page_path}.png")
  end

end
