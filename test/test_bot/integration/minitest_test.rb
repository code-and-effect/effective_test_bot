require 'test_helper'

class MinitestTest < ActionDispatch::IntegrationTest
  def self.test_order
    :alpha
  end

  test 'A: seeds and fixtures loaded' do
    assert_normal
  end

  test 'B: i can use activerecord to create a user' do
    User.new(:email => 'another@agilestyle.com').save(:validate => false)
    assert_equal 3, User.count
  end

  test 'C: the test database is back to normal' do
    assert_normal
  end

  test 'D: i can use capybara to create a user' do
    user = sign_up()

    assert user.kind_of?(User)
    assert_equal 3, User.count

    assert_signed_in
  end

  test 'E: the test database is back to normal' do
    assert_normal
  end

  test 'F: i am in a new capybara session, not currently signed in (after signing up in D)' do
    assert_signed_out
    sign_in('admin@agilestyle.com')
    assert_signed_in
  end

  test 'G: i am still in a new capybara session, not currently signed in' do
    assert_signed_out
    sign_in_manually('normal@agilestyle.com', 'password')
    assert_signed_in
  end

  test 'H: i can use the with_user helper' do
    assert_signed_out
    as_user(User.first) do
      assert_signed_in
    end
    assert_signed_out
  end

  private

  def assert_normal
    visit root_path
    assert_equal page.status_code, 200

    assert_equal 2, User.count
    assert_equal 1, Effective::Menu.count

    assert_equal 'normal@agilestyle.com', User.first.email
    assert_equal 'admin@agilestyle.com', User.last.email

    assert_equal users(:normal).email, 'normal@agilestyle.com'
  end

  def assert_signed_in
    visit new_user_session_path
    assert_content 'You are already signed in. '
    refute page.has_selector?('form#new_user')
  end

  def assert_signed_out
    visit new_user_session_path
    refute_content 'You are already signed in. '
    assert_content 'Log in'
    assert page.has_selector?('form#new_user')
  end

end
