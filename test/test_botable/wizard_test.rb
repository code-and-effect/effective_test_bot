# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module WizardTest
  protected

  def test_bot_wizard_test(&block)
    sign_in(user) and visit(from_path)

    0.upto(50) do |index|   # Can only test wizards 51 steps long
      assert_page_normal

      yield if block_given?

      if defined?(within_form)
        within(within_form) { fill_form; submit_form; }
      else
        fill_form
        submit_form
      end

      assert_no_assigns_errors

      if to_path.present?
        # Keep going till we hit a certain to_path
        break if page.current_path == to_path
      else
        # Keep going till there's no more submit buttons
        break if all("input[type='submit']").blank?
      end
    end

    save_test_bot_screenshot

    assert_current_path(to_path) if to_path.present?
  end

end
