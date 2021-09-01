# This is all private stuff. See effective_test_bot_form_helper.rb for public DSL

require 'faker'

module EffectiveTestBotFormFaker
  DIGITS = ('1'..'9').to_a
  LETTERS = %w(A B C E G H J K L M N P R S T V X Y) # valid letters of a canadian postal code, eh?
  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON']
  FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF']

  # Generates an appropriately pseudo-random value for the given field
  # Pass in a Hash of fills to define pre-selected values
  #
  # Operates on just string keys, no symbols here
  def faker_value_for_field(field, fills = {})
    field_name = [field.tag_name, field['type']].compact.join('_')
    attributes = field['name'].to_s.gsub(']', '').split('[') # user[something_attributes][last_name] => ['user', 'something_attributes', 'last_name']
    attribute = attributes.last.to_s

    fill_value = fill_value_for_field(fills, attributes, field['value'], field_name)

    # If there is a predefined fill value for this field return it now
    # except for select, checkbox and radio fields which we want to match by value or label
    if fill_value.present? && !['select', 'input_checkbox', 'input_radio'].include?(field_name)
      return fill_value
    end

    case field_name
    when 'input_text'
      classes = field['class'].to_s.split(' ')

      if classes.include?('date') # Let's assume this is a date input.
        if attribute.include?('end') || attribute.include?('expire') # Make sure end dates are after start dates
          Faker::Date.forward(days: 365).strftime('%Y-%m-%d')
        else
          Faker::Date.backward(days: 365).strftime('%Y-%m-%d')
        end
      elsif classes.include?('datetime')
        if attribute.include?('end') || attribute.include?('expire')
          Faker::Date.forward(days: 365).strftime('%Y-%m-%d %H:%m')
        else
          Faker::Date.backward(days: 365).strftime('%Y-%m-%d %H:%m')
        end
      elsif classes.include?('numeric')
        value_for_input_numeric_field(field, "input.numeric[name$='[#{attribute}]']")
      elsif classes.include?('email') || classes.include?('effective_email') || attribute.include?('email')
        Faker::Internet.email
      elsif classes.include?('price') || classes.include?('effective_price')
        4.times.map { DIGITS.sample }.join('') + '.00'
      elsif classes.include?('numeric') || classes.include?('effective_number_text') || classes.include?('effective_integer') || attribute.include?('number')
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
      elsif attribute.include?('postal_code')
        if @filled_country_fields == 'US'
          DIGITS.sample + DIGITS.sample + DIGITS.sample + DIGITS.sample + DIGITS.sample
        else
          LETTERS.sample + DIGITS.sample + LETTERS.sample + ' ' + DIGITS.sample + LETTERS.sample + DIGITS.sample
        end
      elsif attribute.include?('postal') # Make a Canadian postal code
        LETTERS.sample + DIGITS.sample + LETTERS.sample + ' ' + DIGITS.sample + LETTERS.sample + DIGITS.sample
      elsif attribute.include?('zip') && attribute.include?('code') # Make a US zip code
        DIGITS.sample + DIGITS.sample + DIGITS.sample + DIGITS.sample + DIGITS.sample
      elsif attribute.include?('social_insurance_number') || attributes.include?('sin_number')
        "#{DIGITS.sample(3).join} #{DIGITS.sample(3).join} #{DIGITS.sample(3).join}"
      elsif attribute.include?('slug')
        Faker::Lorem.words.join(' ').parameterize
      else
        Faker::Lorem.words.join(' ').capitalize
      end

    when 'input_checkbox'
      value_for_input_checkbox_field(field, fill_value)

    when 'input_color'
      Faker::Color.hex_color

    when 'input_email'
      Faker::Internet.email

    when 'input_file'
      if field['class'].to_s.include?('asset-box-uploader-fileinput')
        "#{File.dirname(__FILE__).sub('test/support', 'test/fixtures')}/documents._test"
      else
        "#{File.dirname(__FILE__).sub('test/support', 'test/fixtures')}/logo.png"
      end

    when 'input_number'
      value_for_input_numeric_field(field, "input[type='number'][name$='[#{attribute}]']")

    when 'input_password'
      # Use the same password throughout a single test. Allows passwords and password_confirmations to match.
      @filled_password_fields ||= Faker::Internet.password

    when 'input_radio'
      value_for_input_radio_field(field, fill_value)

    when 'select', 'select_select-one'
      value_for_input_select_field(field, fill_value)

    when 'select_select-multiple'
      1.upto(3).to_a.map { value_for_input_select_field(field, fill_value) }.uniq

    when 'input_tel'
      d = 10.times.map { DIGITS.sample }
      d[0] + d[1] + d[2] + '-' + d[3] + d[4] + d[5] + '-' + d[6] + d[7] + d[8] + d[9]

    when 'input_url'
      Faker::Internet.url

    when 'textarea', 'textarea_textarea'
      Faker::Lorem.paragraph

    when 'input_hidden'
      Faker::Lorem.paragraph

    when 'input_submit', 'input_search', 'input_button'
      nil

    else
      raise "fill_value unsupported field type: #{field_name}"
    end
  end

  private

  def fill_value_for_field(fills, attributes, value, field_name)
    return nil if fills.blank? || (attributes.blank? && value.blank?)

    fill = nil

    # Match by attributes
    key = nil

    attributes.reverse_each do |name|  # match last_name, then something_attributes.last_name, then user.something_attributes.last_name
      key = (key.present? ? "#{name}.#{key}" : name) # builds up the string as we go along

      if fills.key?(key)
        fill = fills[key].to_s
        fill = :unselect if ['select', 'input_file'].include?(field_name) && fills[key].blank?
      end

      break if fill.present?
    end

    # Match by value
    fill ||= fills[value]

    # If this is a file field, make sure the file is present at Rails.root/test/fixtures/
    if fill.present? && fill != :unselect && field_name == 'input_file'
      filename = (fill.to_s.include?('/') ? fill : "#{Rails.root}/test/fixtures/#{fill}")
      raise("Warning: Unable to load fill file #{fill}. Expected file #{filename}") unless File.exists?(filename)
      return filename
    end

    fill.presence
  end

  def value_for_input_select_field(field, fill_value)
    return fill_value if fill_value == :unselect
    country_code = field['name'].to_s.include?('country_code')

    if fill_value.present? # accept a value or text
      field.all('option:enabled', wait: false).each do |option|
        if (option.text == fill_value || option.value.to_s == fill_value)
          @filled_country_fields = option.value if country_code
          return option.text
        end
      end
    end

    option = field.all('option:enabled', wait: false).select { |option| option.value.present? }.sample

    @filled_country_fields = option.try(:value) if country_code # So Postal Code can be set to a valid one

    option.try(:text) || ''
  end

  def value_for_input_checkbox_field(field, fill_value)
    if !fill_value.nil?
      if truthy?(fill_value)
        true
      elsif falsey?(fill_value)
        false
      else
        fill_values = Array(fill_value)  # Allow an array of fill values to be passed
        (fill_values.include?(field['value']) || fill_values.include?(field.find(:xpath, '..').text))
      end
    elsif field['required'].nil? == false
      true
    elsif field['value'] == 'true'
      true
    elsif field['value'] == 'false'
      false
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
    elsif fill_value.present?
      nil
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

    if (field['step'] == '1' || field['class'].to_s.split(' ').include?('integer'))
      number = number.to_i
    end

    return number if field['max'].blank?

    shared_max_fields = all(selector, wait: false)
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

  def truthy?(value)
    TRUE_VALUES.include?(value)
  end

  def falsey?(value)
    FALSE_VALUES.include?(value)
  end

end
