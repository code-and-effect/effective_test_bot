# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module WizardTest
  protected

  def test_bot_wizard_test
    sign_in(user)

    visit(from_path)

    0.upto(50) do |index|   # Can only test wizards 51 steps long
      assert_page_status
      assert_page_title
      assert_no_js_errors

      if defined?(within_form)
        within(within_form) do
          fill_form
          submit_form
        end
      else
        fill_form
        submit_form
      end

      break if page.current_path == to_path
    end

    assert_current_path to_path
  end

end
