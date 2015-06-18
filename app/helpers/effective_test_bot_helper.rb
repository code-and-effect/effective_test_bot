module EffectiveTestBotHelper
  def as_user(user)
    sign_in(user); yield; logout
  end

  def synchronized(&block)
    synchronize!; yield
  end

  def synchronize!
    find('html') # This makes sure capybara is done
  end

  def sign_in(user) # Warden::Test::Helpers
    user.kind_of?(String) == true ? login_as(User.find_by_email(user)) : login_as(user)
  end

  def sign_in_manually(email, password)
    visit new_user_session_path

    within('form#new_user') do
      fill_form(:email => email, :password => password)
      submit_form
    end
  end

  def sign_up(email = Faker::Internet.email, password = Faker::Internet.password)
    visit new_user_registration_path

    within('form#new_user') do
      fill_form(:email => email, :password => password, :password_confirmation => password)
      submit_form
    end

    synchronized { User.find_by_email(email) }
  end



  # fill_form(:email => 'somethign@soneone.com', :password => 'blahblah', 'user.last_name' => 'hlwerewr')
  def fill_form(fills = {})
    fills = HashWithIndifferentAccess.new(fills)

    all('input,select,textarea').each do |field|
      case [field.tag_name, field['type']].compact.join('_')
      when 'input_text', 'input_email', 'input_password', 'input_tel', 'input_number', 'textarea'
        field.set(fill_value(field, fills))
      when 'input_checkbox', 'input_radio'
        field.set(fill_value(field, fills)) # TODO
      when 'select'
        field.select(fill_value(field, fills), match: :first)
      when 'input_file'
        puts "Warning, input_file not yet supported"
      when 'input_submit'
        # Do nothing
      else
        raise "unsupported field type #{[field.tag_name, field['type']].compact.join('_')}"
      end
    end
  end

  # Operates on just string keys
  def fill_value(field, fills = nil)
    attributes = field['name'].to_s.gsub(']', '').split('[') # user[something_attributes][last_name] => ['user', 'something_attributes', 'last_name']
    field_name = [field.tag_name, field['type']].compact.join('_')
    fill_value = nil

    if fills.present?
      key = nil
      attributes.reverse_each do |name|
        key = (key.present? ? "#{name}.#{key}" : name)

        if fills.key?(key)
          fill_value = fills[key]

          if field_name == 'select'
            break
          else
            return fill_value
          end
        end
      end
    end

    case field_name
    when 'input_email'
      Faker::Internet.email
    when 'input_number'
      Faker::Number.number(4)
    when 'input_password'
      Faker::Internet.password
    when 'input_tel'
      digits = ('1'..'9').to_a
      d = 10.times.map { digits.sample }
      d[0] + d[1] + d[2] + '-' + d[3] + d[4] + d[5] + '-' + d[6] + d[7] + d[8] + d[9]
    when 'input_text'
      classes = field['class'].to_s.split(' ')

      if classes.include?('date') # Let's assume this is a date input.
        Faker::Date.backward(365).strftime('%y-%m-%d')
      elsif classes.include?('datetime')
        Faker::Date.backward(365).strftime('%y-%m-%d %H:%m')
      elsif attributes.last.to_s.include?('first_name')
        Faker::Name.first_name
      elsif attributes.last.to_s.include?('last_name')
        Faker::Name.last_name
      elsif attributes.last.to_s.include?('name')
        Faker::Name.name
      else
        Faker::Lorem.word
      end
    when 'select'
      if fill_value.present? # accept a value or label
        field.all('option').each do |option|
          return option.text if option.text == fill_value || option.value.to_s == fill_value.to_s
        end
      end

      field.all('option').select { |option| option.value.present? }.sample.try(:text) || '' # Don't select an empty option
    when 'textarea'
      Faker::Lorem.sentence
    when 'input_checkbox'
      [true, false].sample
    when 'input_radio'
      binding.pry
    else
      raise "fill_value unsupported field type: #{field['type']}"
    end
  end

  def submit_form(label = nil)
    if label.present?
      click_on(label)
      #find_field(label).click
    else
      first(:css, "input[type='submit']").click
    end
  end

end
