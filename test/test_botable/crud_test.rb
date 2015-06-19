module CrudTest
  define_method 'test_bot: #new' do
    should_skip!(:new)

    sign_in(user) and visit(new_resource_path)

    assert_page_status
    assert_page_title

    # Make sure there's a form with a submit button
    form_selector = "form#new_#{resource_name}"

    assert_selector form_selector, "page does not contain a form with selector #{form_selector}"
    within(form_selector) do
      assert_selector 'input[type=submit]', 'page form does not contain a submit button'
    end
  end

  define_method 'test_bot: #create valid' do
    should_skip!(:create)

    sign_in(user) and visit(new_resource_path)

    before = { count: resource_class.count, url: page.current_url }

    within("form#new_#{resource_name}") do
      fill_form(resource_attributes)
      submit_form
    end

    after = { count: resource_class.count, url: page.current_url }

    refute_equal before[:count], after[:count], "unable to create #{resource_class} object"
    refute_equal before[:url], after[:url], "unable to create #{resource_class} object"
  end

  define_method 'test_bot: #create invalid' do
    should_skip!(:create)

    sign_in(user) and visit(new_resource_path)
    before = { count: resource_class.count, url: page.current_url }

    within("form#new_#{resource_name}") do
      submit_form # Submit an empty form
    end

    after = { count: resource_class.count, url: page.current_url }

    assert_equal before[:count], after[:count], 'unexpectedly created object anyway'
    assert_equal before[:url], after[:url], 'did not return to #new action'
    assert_page_title :any, 'page title missing after failed validation'
  end

  define_method 'test_bot: #edit' do
    should_skip!(:edit) and sign_in(user) and (resource = create_resource!)

    visit(edit_resource_path(resource))

    assert_page_status
    assert_page_title

    # Make sure there's a form with a submit button
    form_selector = "form#edit_#{resource_name}_#{resource.id}"

    assert_selector form_selector, "page does not contain a form with selector #{form_selector}"
    within(form_selector) do
      assert_selector 'input[type=submit]', 'page form does not contain a submit button'
    end
  end

  define_method 'test_bot: #update valid' do
    should_skip!(:update) and sign_in(user) and (resource = create_resource!)

    visit(edit_resource_path(resource))

    before = { count: resource_class.count, url: page.current_url, updated_at: (resource.updated_at rescue nil) }

    within("form#edit_#{resource_name}_#{resource.id}") do
      fill_form(resource_attributes)
      submit_form
    end
    resource = resource_class.find(resource.id)

    after = { count: resource_class.count, url: page.current_url, updated_at: (resource.updated_at rescue nil) }

    assert_equal before[:count], after[:count], "updating resource unexpectedly changed #{resource_class}.count"
    assert(after[:updated_at] > before[:updated_at], "failed to update resource") if resource.respond_to?(:updated_at)
  end

  define_method 'test_bot: #update invalid' do
    should_skip!(:update) and sign_in(user) and (resource = create_resource!)

    visit(edit_resource_path(resource))

    before = { count: resource_class.count, url: page.current_url, updated_at: (resource.updated_at rescue nil) }

    within("form#edit_#{resource_name}_#{resource.id}") do
      clear_form
      submit_form
    end
    resource = resource_class.find(resource.id)

    after = { count: resource_class.count, url: page.current_url, updated_at: (resource.updated_at rescue nil) }

    assert_equal before[:count], after[:count], "updating resource unexpectedly changed #{resource_class}.count"
    assert_equal(after[:updated_at], before[:updated_at], 'unexpectedly updated object anyway') if resource.respond_to?(:updated_at)
    assert_equal before[:url], after[:url], 'did not return to #edit action'
    assert_page_title :any, 'page title missing after failed validation'
  end

  define_method 'test_bot: #index' do
    should_skip!(:index) and sign_in(user) and (resource = create_resource!)

    visit resources_path

    assert_page_status
    assert_page_title
  end

  define_method 'test_bot: #show' do
    should_skip!(:show) and sign_in(user) and (resource = create_resource!)

    visit resource_path(resource)

    assert_page_status
    assert_page_title
  end

  define_method 'test_bot: #destroy' do
    should_skip!(:destroy) and sign_in(user) and (resource = create_resource!)

    before = { count: resource_class.count, archived: (resource.archived rescue nil) }

    visit_delete(resource_path(resource), user)

    after = { count: resource_class.count, archived: (resource_class.find(resource.id).archived rescue nil) }

    if resource.respond_to?(:archived)
      assert after[:archived] == true, "expected #{resource_class}.archived == true"
    else
      assert(false, "Unable to delete #{resource_class}") if before[:count] == after[:count]
    end
  end

  protected

  def should_skip!(action)
    skip('skipped') unless crud_actions_to_test.include?(action)
    true
  end

  def create_resource!
    visit(new_resource_path)

    within("form#new_#{resource_name}") do
      fill_form(resource_attributes) and submit_form
    end

    refute_equal new_resource_path, page.current_url
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
