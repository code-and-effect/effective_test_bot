# All the methods in this file should not be called from the outside world
# See the DSL files in concerns/test_botable/ for how to call these tests

module MemberTest
  protected

  def test_bot_member_test
    sign_in(user) and (resource = find_or_create_resource!)

    path = url_for(controller: controller, action: action, id: resource.id, only_path: true)

    visit(path)

    assert_page_normal
    assert_flash unless test_bot_skip?(:flash)
    assert_assigns(resource_name) unless (was_redirect?(path) || test_bot_skip?(:assigns))
  end

end
