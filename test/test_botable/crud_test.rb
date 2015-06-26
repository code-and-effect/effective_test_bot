module CrudTest
  def new
    sign_in(user) and visit(new_resource_path)

    assert_page_status
    assert_page_title
    assert_no_js_errors
    assert_assigns resource_name

    # Make sure there's a form with a submit button
    form_selector = "form#new_#{resource_name}"

    assert_selector form_selector, "page does not contain a form with selector #{form_selector}"
    within(form_selector) do
      assert_selector 'input[type=submit]', 'page form does not contain a submit button'
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

    refute_equal before[:count], after[:count], "unable to create #{resource_class} object"
    refute_equal before[:path], after[:path], "unable to create #{resource_class} object"

    # In a rails controller, if i redirect to resources_path it may not assign the instance variable
    # Wheras if I redirect to edit_resource_path I must ensure that the instance variable is set
    assert_assigns(resource_name) if after[:path].include?('/edit/')
    assert(assigns[resource_name]['errors'].blank?) if assigns[resource_name].present?
  end

  def create_invalid
    sign_in(user) and visit(new_resource_path)
    before = { count: resource_class.count }

    within("form#new_#{resource_name}") do
      submit_novalidate_form
    end

    after = { count: resource_class.count }

    assert_equal before[:count], after[:count], 'unexpectedly created object anyway'
    assert_equal resources_path, page.current_path, 'did not return to #create url'
    assert_page_title :any, 'page title missing after failed validation'

    assert_flash :danger
    assert_assigns resource_name
    assert assigns[resource_name]['errors'].present?
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

    assert_selector form_selector, "page does not contain a form with selector #{form_selector}"
    within(form_selector) do
      assert_selector 'input[type=submit]', 'page form does not contain a submit button'
    end

    assert_assigns resource_name
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

    assert_equal before[:count], after[:count], "updating resource unexpectedly changed #{resource_class}.count"
    assert(after[:updated_at] > before[:updated_at], "failed to update resource") if resource.respond_to?(:updated_at)

    assert_flash :success
    # In a rails controller, if i redirect to resources_path it may not assign the instance variable
    # Wheras if I redirect to edit_resource_path I must ensure that the instance variable is set
    assert_assigns(resource_name) if after[:path] == edit_resource_path(resource)
    assert(assigns[resource_name]['errors'].blank?) if assigns[resource_name].present?
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

    assert_equal before[:count], after[:count], "updating resource unexpectedly changed #{resource_class}.count"
    assert_equal(after[:updated_at], before[:updated_at], 'unexpectedly updated object anyway') if resource.respond_to?(:updated_at)
    assert_equal resource_path(resource), page.current_path, 'did not return to #update url'
    assert_page_title :any, 'page title missing after failed validation'

    assert_flash :danger
    assert_assigns resource_name
    assert assigns[resource_name]['errors'].present?
  end

  def index
    sign_in(user) and (resource = find_or_create_resource!)

    visit resources_path

    assert_page_status
    assert_page_title
    assert_no_js_errors
    assert (assigns['datatable'].present? || assigns[resource_name.pluralize].present?), "expected @datatable or @#{resource_name.pluralize} to be set"
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
      assert after[:archived] == true, "expected #{resource_class}.archived == true"
    else
      refute_equal before[:count], after[:count], "unable to delete #{resource_class}"
    end
  end

  protected

  def find_or_create_resource!
    existing = resource_class.last
    existing.present? ? existing : create_resource!
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
