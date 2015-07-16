# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module BaseTest
  private

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
