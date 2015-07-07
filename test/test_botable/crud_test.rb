module CrudTest
  def new
    sign_in(user) and visit(new_resource_path)

    assert_page_status
    assert_page_title
    assert_no_js_errors
    assert_assigns(resource_name)

    # Make sure there's a form with a submit button
    form_selector = "form#new_#{resource_name}"

    assert_selector form_selector, "Expected form with selector #{form_selector}"
    within(form_selector) do
      assert_selector 'input[type=submit]', 'Expected submit button to be present'
    end
  end

  def create_valid
    sign_in(user) and visit(new_resource_path)

    before = { count: resource_class.count, path: page.current_path }

    within("form#new_#{resource_name}") do
      fill_form(resource_attributes)
      submit_form
    end

    after = { count: resource_class.count, path: page.current_path }

    assert_no_unpermitted_params '[create_valid: :unpermitted_params] Expected no unpermitted params' unless skip?(:unpermitted_params)

    refute_equal before[:count], after[:count], "Expected fill_form to create a #{resource_class} object"
    refute_equal(before[:path], after[:path], "[create_valid: :path] Expected unique before and after paths") unless skip?(:path)

    # In a rails controller, if I redirect to resources_path it may not assign the instance variable
    # Wheras if I redirect to edit_resource_path I must ensure that the instance variable is set
    assert_assigns(resource_name) if after[:path].include?('/edit/')
    assert_equal(nil, assigns[resource_name]['errors'], "Expected @#{resource_name}['errors'] to be blank") if assigns[resource_name].present?
  end

  def create_invalid
    sign_in(user) and visit(new_resource_path)
    before = { count: resource_class.count }

    within("form#new_#{resource_name}") do
      clear_form
      submit_novalidate_form
    end

    after = { count: resource_class.count }

    assert_equal before[:count], after[:count], "Expected: #{resource_class}.count to be unchanged"
    assert_page_title :any, 'Expected page title to be present after failed validation'

    assert_flash :danger
    assert_assigns resource_name
    refute_equal nil, assigns[resource_name]['errors'], "Expected @#{resource_name}['errors'] to be present"

    assert_equal(resources_path, page.current_path, "[create_invalid: :path] Expected current_path to match resource #create path") unless skip?(:path)
  end

  def edit
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))

    assert_page_status
    assert_page_title
    assert_no_js_errors
    assert_assigns resource_name

    # Make sure there's a form with a submit button
    form_selector = "form#edit_#{resource_name}_#{resource.id}"

    assert_selector form_selector, "Expected form with selector #{form_selector}"
    within(form_selector) do
      assert_selector 'input[type=submit]', 'Expected submit button to be present'
    end
  end

  def update_valid
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))

    before = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    within("form#edit_#{resource_name}_#{resource.id}") do
      fill_form(resource_attributes)
      submit_form
    end
    resource = resource_class.find(resource.id)

    after = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    assert_no_unpermitted_params '[update_valid: :unpermitted_params] Expected no unpermitted params' unless skip?(:unpermitted_params)

    assert_equal before[:count], after[:count], "Expected #{resource_class}.count to be unchanged"
    refute_equal(before[:updated_at], after[:updated_at], "Expected @#{resource_name}.updated_at to have changed") if resource.respond_to?(:updated_at)

    assert_flash :success

    # In a rails controller, if i redirect to resources_path it may not assign the instance variable
    # Wheras if I redirect to edit_resource_path I must ensure that the instance variable is set
    assert_assigns(resource_name) if after[:path] == edit_resource_path(resource)
    assert_equal(nil, assigns[resource_name]['errors'], "Expected @#{resource_name}['errors'] to be blank") if assigns[resource_name].present?
  end

  def update_invalid
    sign_in(user) and (resource = find_or_create_resource!)

    visit(edit_resource_path(resource))

    before = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    within("form#edit_#{resource_name}_#{resource.id}") do
      clear_form
      submit_novalidate_form
    end
    resource = resource_class.find(resource.id)

    after = { count: resource_class.count, updated_at: (resource.updated_at rescue nil) }

    assert_equal before[:count], after[:count], "Expected: #{resource_class}.count to be unchanged"
    assert_equal(before[:updated_at], after[:updated_at], "Expected @#{resource_name}.updated_at to be unchanged") if resource.respond_to?(:updated_at)
    assert_page_title :any, 'Expected page title to be present after failed validation'

    assert_flash :danger
    assert_assigns resource_name
    refute_equal(nil, assigns[resource_name]['errors'], "Expected @#{resource_name}['errors'] to be present") if assigns[resource_name].present?

    assert_equal(resource_path(resource), page.current_path, "[update_invalid: :path] Expected current_path to match resource #update path") unless skip?(:path)
  end

  def index
    sign_in(user) and (resource = find_or_create_resource!)

    visit resources_path

    assert_page_status
    assert_page_title
    assert_no_js_errors
    assert((assigns['datatable'].present? || assigns[resource_name.pluralize].present?), "[index: :assigns] Expected @#{resource_name.pluralize} or @datatable to be present") unless skip?(:assigns)
  end

  def show
    sign_in(user) and (resource = create_resource!)

    visit resource_path(resource)

    assert_page_status
    assert_page_title
    assert_no_js_errors
    assert_assigns resource_name
  end

  def destroy
    sign_in(user) and (resource = find_or_create_resource!)

    before = { count: resource_class.count, archived: (resource.archived rescue nil) }

    visit_delete(resource_path(resource), user)

    after = { count: resource_class.count, archived: (resource_class.find(resource.id).archived rescue nil) }

    assert_flash :success

    if resource.respond_to?(:archived)
      assert after[:archived] == true, "Expected #{resource_class}.archived? to be true"
    else
      refute_equal before[:count], after[:count], "Expected: #{resource_class}.count to decrement by 1"
    end
  end

  protected

  def skip?(test)
    skips.include?(test)
  end

  def find_or_create_resource!
    existing = resource_class.last
    (existing.present? && !existing.kind_of?(User)) ? existing : create_resource!
  end

  def create_resource!
    visit(new_resource_path)

    within("form#new_#{resource_name}") do
      fill_form(resource_attributes) and submit_form
    end

    resource_class.last
  end

  private

  def resources_path # index, create
    polymorphic_path([*controller_namespace, resource_class])
  end

  def resource_path(resource) # show, update, destroy
    polymorphic_path([*controller_namespace, resource])
  end

  def new_resource_path # new
    new_polymorphic_path([*controller_namespace, resource])
  end

  def edit_resource_path(resource) # edit
    edit_polymorphic_path([*controller_namespace, resource])
  end
end
