# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module MemberTest

  protected

  def test_bot_member_test
    puts "RUNNIGN TEST BOT MEMBER TEST Job.count == #{Job.count}"

    sign_in(user) and (resource = find_or_create_resource!)

    path = path_for(controller: controller, action: action, id: resource.id)
    puts "URL FOR #{path}"

    visit(path)

    assert_page_status
    assert_page_title
    assert_no_js_errors
    assert_assigns resource_name

    #page.save_screenshot("#{page_path}.png")
  end

end
