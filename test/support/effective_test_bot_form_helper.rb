require 'timeout'

module EffectiveTestBotFormHelper
  DIGITS = ('1'..'9').to_a
  LETTERS = ('A'..'Z').to_a

  # fill_form(:email => 'somethign@soneone.com', :password => 'blahblah', 'user.last_name' => 'hlwerewr')
  def fill_form(fills = {})
    fills = HashWithIndifferentAccess.new(fills)

    # Support for the cocoon gem
    all('a.add_fields[data-association-insertion-template]').each do |cocoon_add_field|
      [1,2].sample.times { cocoon_add_field.click() }
    end

    all('input,select,textarea').each do |field|
      case [field.tag_name, field['type']].compact.join('_')
      when 'input_text', 'input_email', 'input_password', 'input_tel', 'input_number', 'textarea'
        field.set(fill_value(field, fills))
      when 'input_checkbox', 'input_radio'
        field.set(fill_value(field, fills)) # TODO
      when 'select'
        field.select(fill_value(field, fills), match: :first)
      when 'input_file'
        file_path = fill_value(field, fills)
        field['class'].include?('asset-box-uploader-fileinput') ? upload_effective_asset(field, file_path) : field.set(file_path)
      when 'input_submit', 'input_search'
        # Do nothing
      else
        raise "unsupported field type #{[field.tag_name, field['type']].compact.join('_')}"
      end
    end
  end

  def clear_form
    all('input,select,textarea').each { |field| (field.set('') rescue false) }
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
          ['select'].include?(field_name) ? break : (return fill_value)
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
      d = 10.times.map { DIGITS.sample }
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
      elsif attributes.last.to_s.include?('postal') # Make a Canadian Postal Code
        LETTERS.sample + DIGITS.sample + LETTERS.sample + ' ' + DIGITS.sample + LETTERS.sample + DIGITS.sample
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
      [true, false].sample
    when 'input_file'
      "#{File.dirname(__FILE__)}/effective_assets_upload_file._test"
    else
      raise "fill_value unsupported field type: #{field['type']}"
    end
  end

  # page.execute_script "$('form#new_#{resource_name}').submit();"
  def submit_form(label = nil)
    if label.present?
      click_on(label)
    else
      first(:css, "input[type='submit']").click
    end
    synchronize!
  end

  # Submit form after disabling any HTML5 validations
  def submit_novalidate_form(label = nil)
    page.execute_script "for(var f=document.forms,i=f.length;i--;)f[i].setAttribute('novalidate','');"
    submit_form(label)
  end

  # The field here is going to be the %input{:type => file}. Files can be one or more pathnames
  # http://stackoverflow.com/questions/5188240/using-selenium-to-imitate-dragging-a-file-onto-an-upload-element/11203629#11203629
  def upload_effective_asset(field, files)
    files = Array(files)
    uid = field['id']

    page.driver.allow_url(Effective::Asset.s3_base_path)

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
