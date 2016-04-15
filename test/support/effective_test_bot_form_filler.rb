require 'timeout'

module EffectiveTestBotFormFiller
  DIGITS = ('1'..'9').to_a
  LETTERS = ('A'..'Z').to_a

  # Fill a boostrap tabs based form
  def fill_bootstrap_tabs_form(fills = HashWithIndifferentAccess.new, boostrap_tab_elements = nil)
    fills = HashWithIndifferentAccess.new(fills) unless fills.kind_of?(HashWithIndifferentAccess)

    tabs = boostrap_tab_elements || all("a[data-toggle='tab']")

    # If there's only 1 tab, just fill it out
    (fill_form_fields(fills) and return) unless tabs.length > 1

    # If there's more than one tab:
    # We first fill in all fields that are outside of the tab-content
    # Then we start at the first, and go left-to-right through all the tabs
    # clicking each one and filling any form fields found within

    active_tab = find("li.active > a[data-toggle='tab']")
    tab_content = find('div' + active_tab['href']).find(:xpath, '..')

    excluding_fields_with_parent(tab_content) { fill_form_fields(fills) }

    # Refresh the tabs, as they may have changed
    tabs = all("a[data-toggle='tab']")

    # Click through each tab and fill the form inside it.
    tabs.each do |tab|
      # changing the call to to fill_bootstrap_tabs_form for recursiveness should work
      # but it would be an extra all() lookup, and probably not worth it.
      tab.click()
      synchronize!
      save_test_bot_screenshot

      within('div' + tab['href']) { fill_form_fields(fills) }
    end

  end

  # Only fills in visible fields
  # fill_form(:email => 'somethign@soneone.com', :password => 'blahblah', 'user.last_name' => 'hlwerewr')
  def fill_form_fields(fills = HashWithIndifferentAccess.new)
    fills = HashWithIndifferentAccess.new(fills) unless fills.kind_of?(HashWithIndifferentAccess)

    save_test_bot_screenshot

    # Support for the cocoon gem
    all('a.add_fields[data-association-insertion-template]').each do |field|
      next if skip_form_field?(field)

      if EffectiveTestBot.tour_mode_extreme?
        2.times { field.click(); save_test_bot_screenshot }
      else
        2.times { field.click() }
        save_test_bot_screenshot
      end
    end

    all('input,select,textarea', visible: false).each do |field|
      next if skip_form_field?(field)
      skip_field_screenshot = false

      case [field.tag_name, field['type']].compact.join('_')
      when 'input_text', 'input_email', 'input_password', 'input_tel', 'input_number', 'input_checkbox', 'input_radio'
        field.set(value_for_field(field, fills))
      when 'textarea'
        value = value_for_field(field, fills)
        field['class'].to_s.include?('ckeditor') ? fill_ckeditor_text_area(field, value) : field.set(value)
      when 'select'
        if EffectiveTestBot.tour_mode_extreme? && field['class'].to_s.include?('select2') # select2
          page.execute_script("try { $('select##{field['id']}').select2('open'); } catch(e) {};")
          save_test_bot_screenshot
        end

        field.select(value_for_field(field, fills), match: :first)

        if EffectiveTestBot.tour_mode_extreme? && field['class'].to_s.include?('select2')
          page.execute_script("try { $('select##{field['id']}').select2('close'); } catch(e) {};")
        end
      when 'input_file'
        if field['class'].to_s.include?('asset-box-uploader-fileinput')
          upload_effective_asset(field, value_for_field(field, fills))
        else
          field.set(value_for_field(field, fills))
        end
      when 'input_submit', 'input_search'
        skip_field_screenshot = true
        # Do nothing
      else
        raise "unsupported field type #{[field.tag_name, field['type']].compact.join('_')}"
      end

      if EffectiveTestBot.tour_mode_extreme?
        save_test_bot_screenshot unless skip_field_screenshot
      end
    end

    # Clear any value_for_field momoized values
    @filled_numeric_fields = nil
    @filled_password_fields = nil
    @filled_radio_fields = nil

    save_test_bot_screenshot
  end

  # Generates an appropriately pseudo-random value for the given field
  # Pass in a Hash of fills to define pre-selected values
  #
  # Operates on just string keys, no symbols here

  def value_for_field(field, fills = nil)
    field_name = [field.tag_name, field['type']].compact.join('_')
    attributes = field['name'].to_s.gsub(']', '').split('[') # user[something_attributes][last_name] => ['user', 'something_attributes', 'last_name']
    attribute = attributes.last.to_s

    fill_value = fill_value_for_field(fills, attributes)

    # If there is a predefined fill value for this field return it now
    # except for select, checkbox and radio fields which we want to match by value or label
    if fill_value.present? && !['select', 'input_checkbox', 'input_radio'].include?(field_name)
      return fill_value
    end

    case field_name
    when 'input_text'
      classes = field['class'].to_s.split(' ')

      if classes.include?('date') # Let's assume this is a date input.
        if attribute.include?('end') # Make sure end dates are after start dates
          Faker::Date.forward(365).strftime('%Y-%m-%d')
        else
          Faker::Date.backward(365).strftime('%Y-%m-%d')
        end
      elsif classes.include?('datetime')
        if attribute.include?('end')
          Faker::Date.forward(365).strftime('%Y-%m-%d %H:%m')
        else
          Faker::Date.backward(365).strftime('%Y-%m-%d %H:%m')
        end
      elsif classes.include?('numeric')
        value_for_input_numeric_field(field, "input.numeric[name$='[#{attribute}]']")
      elsif classes.include?('email') || attribute.include?('email')
        Faker::Internet.email
      elsif classes.include?('price') # effective_form_inputs price
        4.times.map { DIGITS.sample }.join('') + '.00'
      elsif classes.include?('numeric')
        min = (Float(field['min']) rescue 1)
        max = (Float(field['max']) rescue 1000)
        number = Random.new.rand(min..max)
        number.kind_of?(Float) ? number.round(2) : number
      elsif attribute.include?('first_name')
        Faker::Name.first_name
      elsif attribute.include?('last_name')
        Faker::Name.last_name
      elsif attribute.include?('website')
        Faker::Internet.url
      elsif attribute.include?('city')
        Faker::Address.city
      elsif attribute.include?('address2')
        Faker::Address.secondary_address
      elsif attribute.include?('address')
        Faker::Address.street_address
      elsif attribute.include?('name')
        Faker::Name.name
      elsif attribute.include?('postal') # Make a Canadian postal code
        LETTERS.sample + DIGITS.sample + LETTERS.sample + ' ' + DIGITS.sample + LETTERS.sample + DIGITS.sample
      elsif attribute.include?('zip') && attribute.include?('code') # Make a US zip code
        DIGITS.sample + DIGITS.sample + DIGITS.sample + DIGITS.sample + DIGITS.sample
      elsif attribute.include?('slug')
        Faker::Lorem.words(3).join(' ').parameterize
      else
        Faker::Lorem.words(3).join(' ').capitalize
      end

    when 'input_checkbox'
      value_for_input_checkbox_field(field, fill_value)

    when 'input_email'
      Faker::Internet.email

    when 'input_file'
      "#{File.dirname(__FILE__)}/important_documents._test"

    when 'input_number'
      value_for_input_numeric_field(field, "input[type='number'][name$='[#{attribute}]']")

    when 'input_password'
      # Use the same password throughout a single test. Allows passwords and password_confirmations to match.
      @filled_password_fields ||= Faker::Internet.password

    when 'input_radio'
      value_for_input_radio_field(field, fill_value)

    when 'select'
      if fill_value.present? # accept a value or text
        field.all('option:enabled').each do |option|
          return option.text if (option.text == fill_value || option.value.to_s == fill_value)
        end
      end

      field.all('option:enabled').select { |option| option.value.present? }.sample.try(:text) || '' # Don't select an empty option

    when 'input_tel'
      d = 10.times.map { DIGITS.sample }
      d[0] + d[1] + d[2] + '-' + d[3] + d[4] + d[5] + '-' + d[6] + d[7] + d[8] + d[9]

    when 'textarea'
      Faker::Lorem.paragraph

    else
      raise "fill_value unsupported field type: #{field['type']}"
    end
  end

  def value_for_input_checkbox_field(field, fill_value)
    if fill_value.present?
      fill_values = Array(fill_value)  # Allow an array of fill values to be passed
      (fill_values.include?(field['value']) || fill_values.include?(field.find(:xpath, '..').text))
    elsif field['value'] == 'true'
      true
    elsif field['value'] == 'false'
      false
    elsif field['required'].present?
      true
    else
      [true, false].sample
    end
  end

  # The first time we run into a radio button, we definitely want to set it to TRUE so it's definitely selected
  # Subsequent ones, we can randomly true/false
  # Then if we run into something that has a fill_value, we definitely want to set that one to TRUE, and false the rest
  def value_for_input_radio_field(field, fill_value)
    @filled_radio_fields ||= {}

    previous = @filled_radio_fields[field['name']]

    retval =
      if previous == true  # We've selected one of the options before
        [true, false].sample
      elsif previous.kind_of?(String)  # We selected a previous option with a specific fill_value
        false
      else # We've never seen this radio field before
        true
      end

    if fill_value.present? && (fill_value == field['value'] || fill_value == field.find(:xpath, '..').text)
      @filled_radio_fields[field['name']] = fill_value
      true
    else
      @filled_radio_fields[field['name']] ||= true
      retval
    end
  end

  def value_for_input_numeric_field(field, selector)
    min = (Float(field['min']) rescue 0)
    max = (Float(field['max']) rescue 1000)
    number = Random.new.rand(min..max)
    number = (number.kind_of?(Float) ? number.round(2) : number)

    return number if field['max'].blank?

    shared_max_fields = all(selector)
    return number if shared_max_fields.length <= 1

    # So there's definitely 2+ fields that share the same max, named the same
    # We want the total value of all these fields to add upto the max single max value
    @filled_numeric_fields ||= {}
    @filled_numeric_fields[selector] ||= max

    available = @filled_numeric_fields[selector]

    amount = if max.kind_of?(Float)
      (((max * 1000.0) / shared_max_fields.length.to_f).ceil() / 1000.0).round(2)
    else
      (max / shared_max_fields.length.to_f).ceil
    end
    amount = [[amount, min].max, available].min

    @filled_numeric_fields[selector] = (available - amount)
    amount
  end

  def fill_ckeditor_text_area(field, value)
    value = "<p>#{value.gsub("'", '')}</p>"
    page.execute_script("try { CKEDITOR.instances['#{field['id']}'].setData('#{value}'); } catch(e) {};")
  end

  # The field here is going to be the %input{:type => file}. Files can be one or more pathnames
  # http://stackoverflow.com/questions/5188240/using-selenium-to-imitate-dragging-a-file-onto-an-upload-element/11203629#11203629
  def upload_effective_asset(field, file)
    uid = field['id']
    field.set(file)

    # Wait till the Uploader bar goes away
    begin
      Timeout.timeout(5) do
        within("#asset-box-input-#{uid}") do
          within('.uploads') do
            while (first('.upload').present? rescue false) do
              save_test_bot_screenshot if EffectiveTestBot.tour_mode_extreme?
              sleep(0.5)
            end
          end
        end
      end
    rescue Timeout::Error
      puts "file upload timed out after 5s"
    end
  end

  def close_effective_date_time_picker(field)
    page.execute_script("try { $('input##{field['id']}').data('DateTimePicker').hide(); } catch(e) {};")
  end

  private

  def fill_value_for_field(fills, attributes)
    return if fills.blank? || attributes.blank?

    key = nil
    attributes.reverse_each do |name|  # match last_name, then something_attributes.last_name, then user.something_attributes.last_name
      key = (key.present? ? "#{name}.#{key}" : name) # builds up the string as we go along
      return fills[key].to_s if fills.key?(key)
    end

    nil
  end

  # Takes a capybara element
  def excluding_fields_with_parent(element, &block)
    @test_bot_excluded_fields_xpath = element.path
    yield
    @test_bot_excluded_fields_xpath = nil
  end

  def skip_form_field?(field)
    field.reload # Handle a field changing visibility/disabled state from previous form field manipulations

    ckeditor = (field.tag_name == 'textarea' && field['class'].to_s.include?('ckeditor'))

    (field.visible? == false && !ckeditor) ||
    field.disabled? ||
    ['true', true, 1].include?(field['data-test-bot-skip']) ||
    (@test_bot_excluded_fields_xpath.present? && field.path.include?(@test_bot_excluded_fields_xpath))
  end

end
