# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module WizardTest
  protected

  def test_bot_wizard_test(&block)
    sign_in(user)

    if from.kind_of?(Symbol) && defined?(step)
      visit(public_send(from, id: step))
    else
      visit(from)
    end

    paths = []
    0.upto(50) do |index|   # Can only test wizards 51 steps long
      assert_page_normal

      yield if block_given?

      # If we are on the same page as last time, use submit_form(last: true)
      # to click the last submit button on the page
      last = (paths[index-1] == page.current_path)

      if defined?(within_form)
        within(within_form) { fill_form; submit_form(last: last); }
      else
        fill_form
        submit_form(last: last)
      end

      assert_no_flash_errors unless test_bot_skip?(:no_flash_errors)

      if to.present?
        # Keep going till we hit a certain to_path
        break if page.current_path == to
      end

      # Keep going till there's no more submit buttons
      break if all("input[type='submit']").blank?

      paths << page.current_path.to_s
    end

    save_test_bot_screenshot

    assert_current_path(to) if to.present?
  end

end
