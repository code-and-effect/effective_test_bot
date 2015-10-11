require 'timeout'

module EffectiveTestBotFormFiller
  DIGITS = ('1'..'9').to_a
  LETTERS = ('A'..'Z').to_a

  # Fill a boostrap tabs based form
  def fill_bootstrap_tabs_form(fills = {}, boostrap_tab_elements = nil)
    fills = HashWithIndifferentAccess.new(fills) unless fills.kind_of?(HashWithIndifferentAccess)

    tabs = boostrap_tab_elements || all("a[data-toggle='tab']")

    # If there's only 1 tab, just fill it out
    (fill_form_fields(fills) and return) unless tabs.length > 1

    # If there's more than one tab:
    # We first fill in all fields that are outside of the tab-content
    # Then we start at the first, and go left-to-right through all the tabs
    # clicking each one and filling any form fields found within

    active_tab = find("li.active > a[data-toggle='tab']")
    tab_content = find("div#{active_tab['href']}").find(:xpath, '..')

    excluding_fields_with_parent(tab_content) { fill_form_fields(fills) }

    # Refresh the tabs, as they may have changed
    tabs = all("a[data-toggle='tab']")

    # Click through each tab and fill the form inside it.
    tabs.each do |tab|
      # changing the call to to fill_bootstrap_tabs_form for recursiveness should work
      # but it would be an extra all() lookup, and probably not worth it.
      tab.click()
      save_test_bot_screenshot

      within("div#{tab['href']}") { fill_form_fields(fills) }
    end

  end

  # Only fills in visible fields
  # fill_form(:email => 'somethign@soneone.com', :password => 'blahblah', 'user.last_name' => 'hlwerewr')
  def fill_form_fields(fills = {})
    fills = HashWithIndifferentAccess.new(fills) unless fills.kind_of?(HashWithIndifferentAccess)

    # Support for the cocoon gem
    all('a.add_fields[data-association-insertion-template]').each do |field|
      next if skip_form_field?(field)
      [1, 2].sample.times { field.click(); save_test_bot_screenshot }
    end

    all('input,select,textarea').each do |field|
      next if skip_form_field?(field)

      case [field.tag_name, field['type']].compact.join('_')
      when 'input_text', 'input_email', 'input_password', 'input_tel', 'input_number', 'input_checkbox', 'input_radio', 'textarea'
        field.click(); save_test_bot_screenshot
        field.set(value_for_field(field, fills))
      when 'select'
        if field['class'].to_s.include?('select2') # effective_select
          page.execute_script("try { $('select##{field['id']}').select2('open'); } catch(e) {};")
          save_test_bot_screenshot
        end

        field.select(value_for_field(field, fills), match: :first)
      when 'input_file'
        if field['class'].to_s.include?('asset-box-uploader-fileinput')
          upload_effective_asset(field, value_for_field(field, fills))
        else
          field.set(value_for_field(field, fills))
        end
      when 'input_submit', 'input_search'
        # Do nothing
      else
        raise "unsupported field type #{[field.tag_name, field['type']].compact.join('_')}"
      end

      save_test_bot_screenshot
    end
  end

  # Generates an appropriately pseudo-random value for the given field
  # Pass in a Hash of fills to define pre-selected values
  #
  # Operates on just string keys, no symbols here

  def value_for_field(field, fills = nil)
    field_name = [field.tag_name, field['type']].compact.join('_')
    attributes = field['name'].to_s.gsub(']', '').split('[') # user[something_attributes][last_name] => ['user', 'something_attributes', 'last_name']

    fill_value = fill_value_for_field(fills, attributes)

    # If there is a predefined fill value for this field, return it here
    # except for select fields which are treated differently, so we can match fill values on both the html text or value
    # this edge case is implemented below
    if fill_value.present? && !['select'].include?(field_name)
      return fill_value
    end

    case field_name
    when 'input_text'
      classes = field['class'].to_s.split(' ')

      if classes.include?('date') # Let's assume this is a date input.
        if attributes.last.to_s.include?('end') # Make sure end dates are after start dates
          Faker::Date.forward(365).strftime('%Y-%m-%d')
        else
          Faker::Date.backward(365).strftime('%Y-%m-%d')
        end
      elsif classes.include?('datetime')
        if attributes.last.to_s.include?('end')
          Faker::Date.forward(365).strftime('%Y-%m-%d %H:%m')
        else
          Faker::Date.backward(365).strftime('%Y-%m-%d %H:%m')
        end
      elsif classes.include?('price') # effective_form_inputs price
        4.times.map { DIGITS.sample }.join('') + '.00'
      elsif classes.include?('numeric')
        min = (Float(field['min']) rescue 1)
        max = (Float(field['max']) rescue 1000)
        number = Random.new.rand(min..max)
        number.kind_of?(Float) ? number.round(2) : number
      elsif attributes.last.to_s.include?('first_name')
        Faker::Name.first_name
      elsif attributes.last.to_s.include?('last_name')
        Faker::Name.last_name
      elsif attributes.last.to_s.include?('name')
        Faker::Name.name
      elsif attributes.last.to_s.include?('postal') # Make a Canadian Postal Code
        LETTERS.sample + DIGITS.sample + LETTERS.sample + ' ' + DIGITS.sample + LETTERS.sample + DIGITS.sample
      else
        Faker::Lorem.word
      end

    when 'select'
      if fill_value.present? # accept a value or text
        field.all('option:enabled').each do |option|
          return option.text if (option.text == fill_value || option.value.to_s == fill_value)
        end
      end

      field.all('option:enabled').select { |option| option.value.present? }.sample.try(:text) || '' # Don't select an empty option
    when 'input_number'
      min = (Float(field['min']) rescue 1)
      max = (Float(field['max']) rescue 1000)
      number = Random.new.rand(min..max)
      number.kind_of?(Float) ? number.round(2) : number
    when 'input_email'
      Faker::Internet.email
    when 'input_password'
      # Use the same password throughout a single test. Allows passwords and password_confirmations to match.
      @test_bot_current_password ||= Faker::Internet.password
    when 'input_tel'
      d = 10.times.map { DIGITS.sample }
      d[0] + d[1] + d[2] + '-' + d[3] + d[4] + d[5] + '-' + d[6] + d[7] + d[8] + d[9]
    when 'textarea'
      Faker::Lorem.sentence
    when 'input_checkbox'
      [true, false].sample
    when 'input_radio'
      [true, false].sample
    when 'input_file'
      "#{File.dirname(__FILE__)}/effective_assets_upload_file._test"
    else
      raise "fill_value unsupported field type: #{field['type']}"
    end
  end

  # The field here is going to be the %input{:type => file}. Files can be one or more pathnames
  # http://stackoverflow.com/questions/5188240/using-selenium-to-imitate-dragging-a-file-onto-an-upload-element/11203629#11203629
  def upload_effective_asset(field, files)
    files = Array(files)
    uid = field['id']

    js = "fileList = Array();"

    files.each_with_index do |file, i|
      # Generate a fake input selector
      page.execute_script("if($('#effectiveAssetsPlaceholder#{i}').length == 0) {effectiveAssetsPlaceholder#{i} = window.$('<input/>').attr({id: 'effectiveAssetsPlaceholder#{i}', type: 'file'}).appendTo('body'); }")

      # Attach file to the fake input selector through Capybara
      page.document.attach_file("effectiveAssetsPlaceholder#{i}", files[i])

      # Build up the fake js event
      js = "#{js} fileList.push(effectiveAssetsPlaceholder#{i}.get(0).files[0]);"
    end

    # Trigger the fake drop event
    page.execute_script("#{js} e = $.Event('drop'); e.originalEvent = {dataTransfer : { files : fileList } }; $('#s3_#{uid}').trigger(e);")

    # Remove the file inputs we created
    page.execute_script("$('input[id^=effectiveAssetsPlaceholder]').remove();")

    # Wait till the Uploader bar goes away
    begin
      Timeout.timeout(files.length * 5) do
        within("#asset-box-input-#{uid}") do
          within('.uploads') do
            while (first('.upload').present? rescue false) do
              save_test_bot_screenshot
              sleep(0.5)
            end
          end
        end
      end
    rescue Timeout::Error
      puts "file upload timed out after #{files.length * 5}s"
    end
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
    field.visible? == false ||
    field.disabled? ||
    ['true', true, 1].include?(field['data-test-bot-skip']) ||
    (@test_bot_excluded_fields_xpath.present? && field.path.include?(@test_bot_excluded_fields_xpath))
  end

end
