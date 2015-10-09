# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module CrudTest
  protected

  def test_bot_new_test
    sign_in(user) and visit(new_resource_path)

    assert_page_normal
    assert_assigns(resource_name) # unskippable

    # Make sure there's a form with a submit button
    form_selector = "form#new_#{resource_name}"

    assert_selector form_selector, "Expected form with selector #{form_selector}"
    within(form_selector) do
      assert_selector 'input[type=submit]', 'Expected submit button to be present'
    end
  end

  def test_bot_create_valid_test
    sign_in(user) and visit(new_resource_path)

    before = { count: resource_class.count, path: page.current_path }

    within("form#new_#{resource_name}") do
      fill_form(resource_attributes)
      test_bot_skip?(:unpermitted_params) ? submit_form : with_raised_unpermitted_params_exceptions { submit_form }
    end

    after = { count: resource_class.count, path: page.current_path }

    assert_page_normal
    assert_no_unpermitted_params unless test_bot_skip?(:unpermitted_params)

    refute_equal before[:count], after[:count], "Expected fill_form to create a #{resource_class} object"
    refute_equal(before[:path], after[:path], "(path) Expected unique before and after paths") unless test_bot_skip?(:path)

    # In a rails controller, if I redirect to resources_path it may not assign the instance variable
    # Wheras if I redirect to edit_resource_path I must ensure that the instance variable is set
    assert_assigns(resource_name) if (after[:path].include?('/edit/') && !test_bot_skip?(:assigns))
    assert_no_assigns_errors(resource_name) unless test_bot_skip?(:no_assigns_errors)
  end

  def test_bot_create_invalid_test
    sign_in(user) and visit(new_resource_path)

    before = { count: resource_class.count }

    within("form#new_#{resource_name}") do
      clear_form
      submit_novalidate_form
    end

    after = { count: resource_class.count }

    assert_page_normal

    assert_equal before[:count], after[:count], "Expected #{resource_class}.count to be unchanged"

    assert_assigns(resource_name) unless test_bot_skip?(:assigns)
    assert_assigns_errors(resource_name) unless test_bot_skip?(:assigns_errors)

    assert_flash(:danger) unless test_bot_skip?(:flash)

    assert_equal(resources_path, page.current_path, "(path) Expected current_path to match resource #create path #{resources_path}") unless test_bot_skip?(:path)
  end

  def test_bot_edit_test
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))

    assert_page_normal
    assert_assigns(resource_name) unless test_bot_skip?(:assigns)

    # Make sure there's a form with a submit button
    form_selector = "form#edit_#{resource_name}_#{resource.id}"

    assert_selector form_selector, "Expected form with selector #{form_selector}"
    within(form_selector) do
      assert_selector 'input[type=submit]', 'Expected input[type=submit] to be present'
    end
  end

  def test_bot_update_valid_test
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))

    before = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    within("form#edit_#{resource_name}_#{resource.id}") do
      fill_form(resource_attributes)
      test_bot_skip?(:unpermitted_params) ? submit_form : with_raised_unpermitted_params_exceptions { submit_form }
    end
    resource = resource_class.find(resource.id)

    after = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    assert_page_normal
    assert_no_unpermitted_params unless test_bot_skip?(:unpermitted_params)

    assert_no_assigns_errors(resource_name) unless test_bot_skip?(:no_assigns_errors)

    assert_equal before[:count], after[:count], "Expected #{resource_class}.count to be unchanged"
    refute_equal(before[:updated_at], after[:updated_at], "(updated_at_changed) Expected @#{resource_name}.updated_at to have changed") if (resource.respond_to?(:updated_at) && !test_bot_skip?(:updated_at_changed))

    assert_flash(:success) unless test_bot_skip?(:flash)

    # In a rails controller, if i redirect to resources_path it may not assign the instance variable
    # Wheras if I redirect to edit_resource_path I must ensure that the instance variable is set
    assert_assigns(resource_name) if (after[:path] == edit_resource_path(resource) && !test_bot_skip?(:assigns))
  end

  def test_bot_update_invalid_test
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))

    before = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    within("form#edit_#{resource_name}_#{resource.id}") do
      clear_form
      submit_novalidate_form
    end
    resource = resource_class.find(resource.id)

    after = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    assert_page_normal
    assert_equal before[:count], after[:count], "Expected: #{resource_class}.count to be unchanged"

    assert_assigns(resource_name) unless test_bot_skip?(:assigns)
    assert_assigns_errors(resource_name) unless test_bot_skip?(:assigns_errors)
    assert_equal(before[:updated_at], after[:updated_at], "Expected @#{resource_name}.updated_at to be unchanged") if resource.respond_to?(:updated_at)

    assert_flash(:danger) unless test_bot_skip?(:flash)

    assert_equal(resource_path(resource), page.current_path, "(path) Expected current_path to match resource #update path") unless test_bot_skip?(:path)
  end

  def test_bot_index_test
    sign_in(user) and (resource = (find_or_create_resource! rescue nil))

    visit resources_path

    assert_page_normal

    assert(
      (assigns['datatable'].present? || assigns[resource_name.pluralize].present?),
      "(assigns) Expected @#{resource_name.pluralize} or @datatable to be present"
    ) unless test_bot_skip?(:assigns)
  end

  def test_bot_show_test
    sign_in(user) and (resource = find_or_create_resource!)

    visit resource_path(resource)

    assert_page_normal
    assert_assigns(resource_name) unless test_bot_skip?(:assigns)
  end

  def test_bot_destroy_test
    sign_in(user) and (resource = find_or_create_resource!)

    before = { count: resource_class.count, archived: (resource.archived rescue nil) }

    visit_delete(resource_path(resource), user)

    after = { count: resource_class.count, archived: (resource_class.find(resource.id).archived rescue nil) }

    # Because of the way delete works, we can't use assert_page_normal()
    # So we just assert the 200 status code, and page title present manually
    # Javascript errors cannot be detected
    assert_equal(200, @visit_delete_page.try(:status_code), '(page_status) Expected 200 HTTP status code') unless test_bot_skip?(:page_status)
    assert((@visit_delete_page.find(:xpath, '//title', visible: false) rescue nil).present?, '(page_title) Expected page title to be present') unless test_bot_skip?(:page_title)

    assert_flash(:success) unless test_bot_skip?(:flash)

    if resource.respond_to?(:archived)
      assert_equal(true, after[:archived], "Expected #{resource_class}.archived? to be true")
    else
      assert_equal before[:count]-1, after[:count], "Expected: #{resource_class}.count to decrement by 1"
    end
  end
end
