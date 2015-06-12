module EffectiveTestBotHelper
  def sign_up(email = Faker::Internet.email, password = Faker::Internet.password)
    visit new_user_registration_path

    within('form#new_user') do
      fill_form(:email => email, :password => password, :password_confirmation => password)
      page.save_screenshot('something1.png')
      submit_form
      page.save_screenshot('something2.png')
    end

    assert_equal page.status_code, 200
    assert_content I18n.t('devise.registrations.signed_up')

    User.find_by_email(email)
  end

  # fill_form(:email => 'somethign@soneone.com', :password => 'blahblah', 'user.last_name' => 'hlwerewr')
  def fill_form(fills = {})
    fills = HashWithIndifferentAccess.new(fills)

    all('input,select').each do |field|
      case field['type']
      when 'text', 'email', 'password'
        field.set(fill_value(field, fills))
      when 'submit'
        # Do nothing
      else
        raise "unsupported field type #{field['type']}"
      end
    end
  end

  # Operates on just string keys
  def fill_value(field, fills = nil)
    names = field['name'].to_s.gsub(']', '').split('[') # user[something_attributes][last_name] => ['user', 'something_attributes', 'last_name']

    if fills.present?
      names.reverse_each do |name|
        key = (key.present? ? "#{name}.#{key}" : name)
        (return fills[key]) if fills.key?(key)
      end
    end

    case field['type']
    when 'email'
      Faker::Internet.email
    when 'password'
      Faker::Internet.password
    when 'text'
      if names.last.include?('first_name')
        Faker::Name.first_name
      elsif names.last.include?('last_name')
        Faker::Name.last_name
      elsif names.last.include?('name')
        Faker::Name.name
      else
        Faker::Lorem.sentence
      end
    else
      raise "fill_value unsupported field type: #{field['type']}"
    end
  end

  def submit_form(label = nil)
    if label.present?
      find_field(label).click
    else
      first(:css, "input[type='submit']").click
    end
  end

end
