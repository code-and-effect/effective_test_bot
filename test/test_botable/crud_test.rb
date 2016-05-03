# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module CrudTest
  protected

  # So this runs every single test over again, but in a screenshot optimized manner
  def test_bot_tour_test
    # This is set by the crud_dsl, from application_test.  It makes sure we don't run a show test if theres no show action
    tests = defined?(current_crud_tests) ? current_crud_tests : []
    tests = tests - [:tour, 'tour'] # Ensure tour doesn't somehow get in here, as it'll recurse forever

    tests.each { |test| send("test_bot_#{test}_test") }

    visit resources_path
    save_test_bot_screenshot
  end

  def test_bot_index_test
    sign_in(user) and (resource = (find_or_create_resource! rescue nil))

    visit resources_path
    save_test_bot_screenshot

    assert_page_normal

    assert(
      (assigns['datatable'].present? || assigns[resource_name.pluralize].present?),
      "(assigns) Expected @#{resource_name.pluralize} or @datatable to be present"
    ) unless test_bot_skip?(:assigns)
  end

  def test_bot_new_test
    sign_in(user) and visit(new_resource_path)
    save_test_bot_screenshot

    assert_page_normal
    assert_assigns(resource_name) # unskippable

    assert_form("form#new_#{resource_name}") unless test_bot_skip?(:form)

    within_if("form#new_#{resource_name}", !test_bot_skip?(:form)) do
      assert_submit_input unless test_bot_skip?(:submit_input)
      assert_jquery_ujs_disable_with unless test_bot_skip?(:jquery_ujs_disable_with)
    end
  end

  def test_bot_create_invalid_test
    sign_in(user) and visit(new_resource_path)

    before = { count: resource_class.count }

    assert_form("form#new_#{resource_name}") unless test_bot_skip?(:form)

    within_if("form#new_#{resource_name}", !test_bot_skip?(:form)) do
      without_screenshots { clear_form }
      submit_novalidate_form
    end

    save_test_bot_screenshot

    after = { count: resource_class.count }

    assert_page_normal

    assert_assigns(resource_name) unless test_bot_skip?(:assigns)
    assert_assigns_errors(resource_name) unless test_bot_skip?(:assigns_errors)

    assert_equal before[:count], after[:count], "Expected #{resource_class}.count to be unchanged"
    assert_equal(resources_path, page.current_path, "(path) Expected current_path to match resource #create path #{resources_path}") unless test_bot_skip?(:path)

    assert_flash(:danger) unless test_bot_skip?(:flash)
  end

  def test_bot_create_valid_test
    sign_in(user) and visit(new_resource_path)
    save_test_bot_screenshot

    before = { count: resource_class.count, path: page.current_path }

    assert_form("form#new_#{resource_name}") unless test_bot_skip?(:form)

    within_if("form#new_#{resource_name}", !test_bot_skip?(:form)) do
      fill_form(resource_attributes)
      submit_form
    end

    save_test_bot_screenshot

    after = { count: resource_class.count, path: page.current_path }

    assert_page_normal

    # In a rails controller, if I redirect to resources_path it may not assign the instance variable
    # Wheras if I redirect to edit_resource_path I must ensure that the instance variable is set
    assert_assigns(resource_name) if (after[:path].include?('/edit/') && !test_bot_skip?(:assigns))
    assert_no_assigns_errors(resource_name) unless test_bot_skip?(:no_assigns_errors)

    refute_equal before[:count], after[:count], "Expected fill_form to create a #{resource_class} object"
    refute_equal(before[:path], after[:path], "(path) Expected unique before and after paths") unless test_bot_skip?(:path)
  end

  def test_bot_show_test
    sign_in(user) and (resource = find_or_create_resource!)

    visit resource_path(resource)
    save_test_bot_screenshot

    assert_page_normal
    assert_assigns(resource_name) unless test_bot_skip?(:assigns)
  end

  def test_bot_edit_test
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))
    save_test_bot_screenshot

    assert_page_normal
    assert_assigns(resource_name) # unskippable
    assert_form("form[id^='edit_#{resource_name}']") unless test_bot_skip?(:form)

    within_if("form[id^='edit_#{resource_name}']", !test_bot_skip?(:form)) do
      assert_submit_input unless test_bot_skip?(:submit_input)
      assert_jquery_ujs_disable_with unless test_bot_skip?(:jquery_ujs_disable_with)
    end
  end

  def test_bot_update_invalid_test
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))
    save_test_bot_screenshot

    before = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    within_if("form[id^='edit_#{resource_name}']", !test_bot_skip?(:form)) do
      clear_form
      submit_novalidate_form
    end

    save_test_bot_screenshot

    resource = resource_class.where(id: resource.id).first

    after = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    assert_page_normal

    assert_assigns(resource_name) unless test_bot_skip?(:assigns)
    assert_assigns_errors(resource_name) unless test_bot_skip?(:assigns_errors)

    assert_equal(resource_path(resource), page.current_path, "(path) Expected current_path to match resource #update path") unless test_bot_skip?(:path)

    assert_equal before[:count], after[:count], "Expected: #{resource_class}.count to be unchanged"
    assert_equal(before[:updated_at], after[:updated_at], "(updated_at) Expected @#{resource_name}.updated_at to be unchanged") if (resource.respond_to?(:updated_at) && !test_bot_skip?(:updated_at))

    assert_flash(:danger) unless test_bot_skip?(:flash)

  end

  def test_bot_update_valid_test
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))
    save_test_bot_screenshot

    before = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    within_if("form[id^='edit_#{resource_name}']", !test_bot_skip?(:form)) do
      fill_form(resource_attributes)
      submit_form
    end

    save_test_bot_screenshot

    resource = resource_class.where(id: resource.id).first

    after = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    assert_page_normal

    # In a rails controller, if i redirect to resources_path it may not assign the instance variable
    # Wheras if I redirect to edit_resource_path I must ensure that the instance variable is set
    if after[:path] == edit_resource_path(resource)
      assert_assigns(resource_name) unless !test_bot_skip?(:assigns)
    end
    assert_no_assigns_errors(resource_name) unless test_bot_skip?(:no_assigns_errors)

    assert_equal before[:count], after[:count], "Expected #{resource_class}.count to be unchanged" unless test_bot_skip?(:count)
    refute_equal(before[:updated_at], after[:updated_at], "(updated_at) Expected @#{resource_name}.updated_at to have changed") if (resource.respond_to?(:updated_at) && !test_bot_skip?(:updated_at))

    assert_flash(:success) unless test_bot_skip?(:flash)
  end

  def test_bot_destroy_test
    sign_in(user) and (resource = find_or_create_resource!)

    before = { count: resource_class.count, archived: (resource.archived rescue nil) }

    # We're going to try to visit the index page and create a link to delete
    visit(resources_path)
    save_test_bot_screenshot

    link_to_delete = find_or_create_rails_ujs_link_to_delete(resource)

    if link_to_delete.present? && (link_to_delete.click() rescue false)
      synchronize!
      save_test_bot_screenshot

      assert_page_normal
      assert_flash(:success) unless test_bot_skip?(:flash)
    else
      # Capybara-webkit can't just make a DELETE request, so we fallback to Selenium
      # We can't use our normal helpers assert_page_normal()
      # So we just assert the 200 status code, and page title present manually
      # Javascript errors cannot be detected

      puts 'test_bot_destroy_test failed to find_or_create_rails_ujs_link_to_delete  Falling back to selenium DELETE request.'
      visit_delete(resource_path(resource), user)
      assert_equal(200, @visit_delete_page.try(:status_code), '(page_status) Expected 200 HTTP status code') unless test_bot_skip?(:page_status)
      assert((@visit_delete_page.find(:xpath, '//title', visible: false) rescue nil).present?, '(page_title) Expected page title to be present') unless test_bot_skip?(:page_title)
    end

    after = { count: resource_class.count, archived: (resource_class.where(id: resource.id).first.try(:archived) rescue nil) }

    if resource.respond_to?(:archived)
      assert_equal(true, after[:archived], "Expected @#{resource_name}.archived? to be true")
    else
      assert_equal before[:count]-1, after[:count], "Expected: #{resource_class}.count to decrement by 1"
    end
  end

end
