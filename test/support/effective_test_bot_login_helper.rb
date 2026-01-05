# This is all assuming you're running Devise

module EffectiveTestBotLoginHelper
  def as_user(user)
    sign_in(user); @test_bot_user = user
    yield
    sign_out; @test_bot_user = nil
  end

  # This is currently hardcoded to use the warden login_as test helper
  def sign_in(user)
    if user.kind_of?(String)
      login_as(devise_user_class.find_by_email!(user))
    elsif user.class.name.end_with?('User')
      raise 'user must be persisted' unless user.persisted?
      user.reload

      devise_scope = user.class.name.underscore.gsub('/', '_').to_sym
      login_as(user, scope: devise_scope)
    elsif user == false
      true # Do nothing
    else
      raise 'sign_in(user) expected a User or an email String'
    end
  end

  # This is currently hardcoded to use the warden logout test helper
  def sign_out
    logout
  end

  def sign_in_manually(user_or_email, password = nil)
    visit (respond_to?(:new_user_session_path) ? new_user_session_path : '/users/sign_in')

    email = (user_or_email.respond_to?(:email) ? user_or_email.email : user_or_email)
    username = (user_or_email.respond_to?(:username) ? user_or_email.username : user_or_email)
    login = (user_or_email.respond_to?(:login) ? user_or_email.login : user_or_email)

    within('form[id^=new][id$=user]') do
      fill_form(email: email, password: password, username: username, login: login)
      submit_novalidate_form
    end
  end

  def sign_up(email: nil, password: nil, **options)
    email ||= Faker::Internet.email
    password ||= "#{Faker::Internet.password}#{Faker::Internet.password}#{Faker::Internet.password}"

    visit (respond_to?(:new_user_registration_path) ? new_user_registration_path : '/users/sign_up')

    within('form[id^=new][id$=user]') do
      fill_form({email: email, password: password, password_confirmation: password}.merge(options))
      submit_novalidate_form
    end

    devise_user_class.find_by_email(email)
  end

  def current_user
    user_id = assigns.dig(current_user_assigns_key, 'id')
    return if user_id.blank?

    devise_user_class.where(id: user_id).first
  end

  def devise_user_class
    (current_user_assigns_class || User)
  end

end
