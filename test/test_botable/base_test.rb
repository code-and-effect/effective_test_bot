# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module BaseTest
  protected

  def assert_page_normal(message = nil)
    return if test_bot_skip?(:normal)

    assert_no_exceptions unless test_bot_skip?(:exceptions)
    assert_page_status unless test_bot_skip?(:page_status)
    assert_no_js_errors unless test_bot_skip?(:no_js_errors)
    assert_page_title unless test_bot_skip?(:page_title)
  end

  private

  # I want to use this same method for the current_test rake test:bot skip functionality
  # As well as the individual assertion skips

  # Only class level dsl methods will have a current_test assigned
  # if you use the action_test_ instance methods, current_test is nil, and test skips won't apply
  # Any global assertion skips will tho
  def test_bot_skip?(assertion = nil)
    # Skip the whole test 'documents#new'
    # this will put SKIP into the minitest output
    skip if (defined?(current_test) && EffectiveTestBot.skip?(current_test))

    # Skip just this assertion sub test 'flash'
    # this will not print anything to the minitest output
    EffectiveTestBot.skip?((current_test if defined?(current_test)), assertion)
  end

  def find_or_create_resource!
    existing = resource_class.last
    (existing.present? && !existing.kind_of?(User)) ? existing : create_resource!
  end

  def create_resource!
    visit(new_resource_path)

    within("form#new_#{resource_name}") do
      fill_form(resource_attributes) and submit_novalidate_form
    end

    resource_class.last
  end

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
