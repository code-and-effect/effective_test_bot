# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module BaseTest
  protected

  def assert_page_normal(message = nil)
    return if test_bot_skip?(:normal)

    assert_authorization unless test_bot_skip?(:authorization)
    assert_no_exceptions unless test_bot_skip?(:exceptions)
    assert_page_status unless test_bot_skip?(:page_status)
    assert_no_js_errors unless test_bot_skip?(:no_js_errors)
    assert_page_title unless (test_bot_skip?(:page_title) || all('head').blank?)
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

  # There are numerous points of failure here, so we want to be very helpful with the error messages
  def find_or_create_resource!
    obj = resource_class.last
    return obj if obj.present? && !obj.kind_of?(User)

    # It doesn't exist, so lets go to the new page and submit a form to build one
    without_screenshots do
      # TODO: enumerate all controller namespaces instead of just admin and members
      new_path = (new_resource_path rescue nil)
      new_path ||= (new_polymorphic_path(resource) rescue nil)
      new_path ||= (new_polymorphic_path([:admin, resource]) rescue nil)
      new_path ||= (new_polymorphic_path([:members, resource]) rescue nil)

      hint = "Unable to find_or_create_resource!\n"
      hint += "Either fixture/seed an instance of #{resource_class} or ensure that submitting form#new_#{resource_name} "
      hint += "on #{(new_path rescue nil) || 'the resource new page'} creates a new #{resource_name}"

      assert(new_path.present?, "TestBotError: Generated polymorphic route new_#{[*controller_namespace, resource_name].compact.join('_')}_path is undefined. #{hint}")

      visit(new_path)

      assert_authorization(message: hint)
      assert_no_exceptions
      assert_page_status

      assert_form("form#new_#{resource_name}", message: "TestBotError: Failed to find form#new_#{resource_name}. #{hint}") unless test_bot_skip?(:form)

      within_if("form#new_#{resource_name}", !test_bot_skip?(:form)) do
        assert_submit_input(message: "TestBotError: Failed to find a visible input[type='submit'] on #{page.current_path}. #{hint}")

        fill_form(resource_attributes)
        submit_novalidate_form

        assert_authorization(message: hint)
        assert_no_exceptions
        assert_page_status
      end

      obj = resource_class.all.last

      if obj.blank?
        visit(new_path)
        obj = resource_class.all.last
      end

      assert obj.present?, "TestBotError: Failed to create a resource after submitting form. Errors: #{(assigns[resource_name] || {})['errors']}\n#{hint}."

      visit root_path
    end

    obj
  end

  # Try to find a link_to_delete already on this page
  # Otherwise create one
  # Returns the link element
  def create_rails_ujs_link_to_delete(resource)
    selector = "a[href='#{destroy_resource_path(resource)}'][data-method='delete']"

    page.execute_script("$('body').prepend($('<a>').attr({href: '#{destroy_resource_path(resource)}', 'data-method': 'delete'}).html('Delete'));")

    (page.document.first(:css, selector) rescue nil)
  end

  def effective_resource
    @effective_resource ||= Effective::Resource.new([controller_namespace, resource_class].join('/'))
  end

  def resources_path # index, create
    effective_resource.action_path(:index)
  end

  def resource_path(resource) # show, update, destroy
    effective_resource.action_path(:show, resource)
  end

  def new_resource_path # new
    effective_resource.action_path(:new)
  end

  def edit_resource_path(resource) # edit
    effective_resource.action_path(:edit, resource)
  end

  def destroy_resource_path(resource)
    effective_resource.action_path(:destroy, resource)
  end

end
