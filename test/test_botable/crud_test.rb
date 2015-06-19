module CrudTest
  define_method 'test_bot: new' do
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

  define_method 'test_bot: create valid' do
    sign_in(user) and visit(new_resource_path)

    count_before = resource_class.count # ActiveRecord

    within("form#new_#{resource_name}") do
      fill_form
      submit_form
    end

    assert_equal count_before, (resource_class.count - 1), 'unable to create resource'
  end


  # define_method 'test_bot: first_test' do
  #   puts "resource is #{resource}"
  #   puts "resource_class is #{resource_class}"
  #   puts "user is #{user}"

  #   assert true
  # end

  # define_method 'test_bot: second_test' do
  #   assert_equal 'normal@agilestyle.com', user.email
  #   assert true
  # end

  # define_method 'test_bot: last_test' do
  #   assert_equal 'normal@agilestyle.com', user.email
  #   assert true
  # end


  private

  def resources_path # index, create
    polymorphic_path([*namespace, resource_class])
  end

  def resource_path # show, update, destroy
    polymorphic_path([*namespace, resource])
  end

  def new_resource_path
    new_polymorphic_path([*namespace, resource])
  end

  def edit_resource_path
    edit_polymorphic_path([*namespace, resource])
  end

end
