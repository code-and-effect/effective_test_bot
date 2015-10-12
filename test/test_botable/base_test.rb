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
    without_screenshots do
      visit(new_resource_path)

      within("form#new_#{resource_name}") do
        fill_form(resource_attributes) and submit_novalidate_form
      end
    end

    resource_class.last
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
