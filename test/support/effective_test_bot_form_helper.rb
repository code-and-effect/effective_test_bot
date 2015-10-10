require 'timeout'

module EffectiveTestBotFormHelper
  DIGITS = ('1'..'9').to_a
  LETTERS = ('A'..'Z').to_a

  def fill_form(fills = {})
    fills = HashWithIndifferentAccess.new(fills) unless fills.kind_of?(HashWithIndifferentAccess)

    save_test_bot_screenshot
    tabs = all("a[data-toggle='tab']")

    if tabs.length > 1
      active_tab = find("li.active > a[data-toggle='tab']")
      tab_content = find("div#{active_tab['href']}").find(:xpath, '..')

      fill_fields(fills, tab_content.path)
    else
      fill_fields(fills)
    end

    # Support bootstrap3 tabs
    #tabs = all("li:not(.active) > a[data-toggle='tab']")
    tabs = all("a[data-toggle='tab']")

    if tabs.length > 1
      tabs.each do |tab|
        tab.click()
        within("div#{tab['href']}") { fill_form(fills) }
      end
    end

    true
  end

  # Only fills in visible fields
  # fill_form(:email => 'somethign@soneone.com', :password => 'blahblah', 'user.last_name' => 'hlwerewr')
  def fill_fields(fills = {}, xpath_to_skip = nil)
    fills = HashWithIndifferentAccess.new(fills) unless fills.kind_of?(HashWithIndifferentAccess)

    # Support for the cocoon gem
    all('a.add_fields[data-association-insertion-template]').each do |field|
      next unless (
        field.visible? &&
        !field.disabled? &&
        field['data-test-bot-skip'] != 'true' &&
        (xpath_to_skip.blank? || !field.path.include?(xpath_to_skip))
      )
      [1,2].sample.times { field.click(); save_test_bot_screenshot }
    end

    all('input,select,textarea').each do |field|
      next unless (
        field.visible? &&
        !field.disabled? &&
        field['data-test-bot-skip'] != 'true' &&
        (xpath_to_skip.blank? || !field.path.include?(xpath_to_skip))
      )

      case [field.tag_name, field['type']].compact.join('_')
      when 'input_text', 'input_email', 'input_password', 'input_tel', 'input_number', 'textarea'
        field.set(fill_field(field, fills))
      when 'input_checkbox', 'input_radio'
        field.set(fill_field(field, fills)) # TODO
      when 'select'
        field.select(fill_field(field, fills), match: :first)
      when 'input_file'
        file_path = fill_field(field, fills)
        field['class'].to_s.include?('asset-box-uploader-fileinput') ? upload_effective_asset(field, file_path) : field.set(file_path)
      when 'input_submit', 'input_search'
        # Do nothing
      else
        raise "unsupported field type #{[field.tag_name, field['type']].compact.join('_')}"
      end

      save_test_bot_screenshot
    end
  end


  # Operates on just string keys
  # This function receives the same fill values that you call fill_form with
  def fill_field(field, fills = nil)
    attributes = field['name'].to_s.gsub(']', '').split('[') # user[something_attributes][last_name] => ['user', 'something_attributes', 'last_name']
    field_name = [field.tag_name, field['type']].compact.join('_')
    fill_value = nil

    if fills.present?
      key = nil
      attributes.reverse_each do |name|  # match last_name, then something_attributes.last_name, then user.something_attributes.last_name
        key = (key.present? ? "#{name}.#{key}" : name) # builds up the string as we go along

        if fills.key?(key)
          fill_value = fills[key]
          # select is treated differently, because we want the passed prefill to match both the html text or value (which is implemented below)
          ['select'].include?(field_name) ? break : (return fill_value)
        end
      end
    end

    case field_name
    when 'input_email'
      Faker::Internet.email
    when 'input_number'
      min = (Float(field['min']) rescue 1)
      max = (Float(field['max']) rescue 1000)
      number = Random.new.rand(min..max)
      number.kind_of?(Float) ? number.round(2) : number
    when 'input_password'
      @test_bot_password ||= Faker::Internet.password  # Use the same password throughout a single test. Allows passwords and password_confirmations to match.
    when 'input_tel'
      d = 10.times.map { DIGITS.sample }
      d[0] + d[1] + d[2] + '-' + d[3] + d[4] + d[5] + '-' + d[6] + d[7] + d[8] + d[9]
    when 'input_text'
      classes = field['class'].to_s.split(' ')

      if classes.include?('date') # Let's assume this is a date input.
        if attributes.last.to_s.include?('end') # Make sure end dates are entered after start dates
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
      elsif classes.include?('price')
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
        field.all('option').each do |option|
          return option.text if option.text == fill_value || option.value.to_s == fill_value.to_s
        end
      end

      field.all('option:enabled').select { |option| option.value.present? }.sample.try(:text) || '' # Don't select an empty option
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

  # page.execute_script "$('form#new_#{resource_name}').submit();"
  # This submits the form, and checks for unpermitted_params and html5 form validation errors
  def submit_form(label = nil)
    assert_no_html5_form_validation_errors unless test_bot_skip?(:no_html5_form_validation_errors)

    if test_bot_skip?(:no_unpermitted_params)
      label.present? ? click_on(label) : first(:css, "input[type='submit']").click
    else
      with_raised_unpermitted_params_exceptions do
        label.present? ? click_on(label) : first(:css, "input[type='submit']").click
      end
    end

    synchronize!
    assert_no_unpermitted_params unless test_bot_skip?(:no_unpermitted_params)

    true
  end

  # Submit form after disabling any HTML5 validations
  def submit_novalidate_form(label = nil)
    page.execute_script "for(var f=document.forms,i=f.length;i--;)f[i].setAttribute('novalidate','');"

    label.present? ? click_on(label) : first(:css, "input[type='submit']").click
    synchronize!
    true
  end

  def clear_form
    all('input,select,textarea').each { |field| (field.set('') rescue false) }
    true
  end

  def with_raised_unpermitted_params_exceptions(&block)
    action = nil

    begin  # This may only work with Rails >= 4.0
      action = ActionController::Parameters.action_on_unpermitted_parameters
      ActionController::Parameters.action_on_unpermitted_parameters = :raise
    rescue => e
      puts 'unable to assign config.action_on_unpermitted_parameters = :raise, (unpermitted_params) assertions may not work.'
    end

    yield

    ActionController::Parameters.action_on_unpermitted_parameters = action if action.present?
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

    # Wait till the Uploader bar goes away
    begin
      Timeout.timeout(files.length * 5) do
        within("#asset-box-input-#{uid}") do
          within('.uploads') do
            sleep(0.25) while (first('.upload').present? rescue false)
          end
        end
      end
    rescue Timeout::Error
      puts "file upload timed out after #{files.length * 5}s"
    end
  end

end
