# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module BaseTest
  protected

  def assert_page_normal(message = nil)
    return if test_bot_skip?(:normal)

    assert_no_exceptions unless test_bot_skip?(:exceptions)
    assert_authorization unless test_bot_skip?(:authorization)
    assert_page_status unless test_bot_skip?(:page_status)
    assert_no_js_errors unless test_bot_skip?(:no_js_errors)
    assert_page_title unless (test_bot_skip?(:page_title) || all('head').blank? || was_download?)
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

      assert_no_exceptions
      assert_authorization(hint)
      assert_page_status

      assert_form("form#new_#{resource_name}", "TestBotError: Failed to find form#new_#{resource_name}. #{hint}") unless test_bot_skip?(:form)

      within_if("form#new_#{resource_name}", !test_bot_skip?(:form)) do
        assert_submit_input("TestBotError: Failed to find a visible input[type='submit'] on #{page.current_path}. #{hint}")

        fill_form(resource_attributes)
        submit_novalidate_form

        assert_no_exceptions
        assert_authorization(hint)
        assert_page_status
      end

      obj = resource_class.last
      assert obj.present?, "TestBotError: Failed to create a resource after submitting form. Errors: #{(assigns[resource_name] || {})['errors']}\n#{hint}."
    end

    obj
  end

  # Try to find a link_to_delete already on this page
  # Otherwise create one
  # Returns the link element
  def find_or_create_rails_ujs_link_to_delete(resource)
    selector = "a[href='#{resource_path(resource)}'][data-method='delete']"
    link_to_delete = page.document.all(selector, visible: false).first # could be nil, but this is a non-blocking selector

    if link_to_delete.present? # Take excessive efforts to ensure it's visible and clickable
      page.execute_script("$('body').prepend($(\"#{selector}\").first().clone().show().removeProp('disabled').html('Delete'));")
    else  # Create our own link
      page.execute_script("$('body').prepend($('<a>').attr({href: '#{resource_path(resource)}', 'data-method': 'delete', 'data-confirm': 'Are you sure?'}).html('Delete'));")
    end

    # capybara-webkit doesn't seem to stop on the alert 'Are you sure?'.
    # Otherwise we'd want to take a screenshot of it

    (page.document.first(:css, selector) rescue nil)
  end

  def resources_path # index, create
    path = polymorphic_path([*controller_namespace, resource_class]) rescue nil
    path || polymorphic_path([*controller_namespace.try(:singularize), resource_class])
  end

  def resource_path(resource) # show, update, destroy
    path = polymorphic_path([*controller_namespace, resource]) rescue nil
    path || polymorphic_path([*controller_namespace.try(:singularize), resource])
  end

  def new_resource_path # new
    path = new_polymorphic_path([*controller_namespace, resource_class]) rescue nil
    path || new_polymorphic_path([*controller_namespace.try(:singularize), resource_class])
  end

  def edit_resource_path(resource) # edit
    path = edit_polymorphic_path([*controller_namespace, resource]) rescue nil
    path || edit_polymorphic_path([*controller_namespace.try(:singularize), resource])
  end
end
