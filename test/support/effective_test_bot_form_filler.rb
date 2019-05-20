# This is all private stuff. See effective_test_bot_form_helper.rb for public DSL

require 'timeout'

module EffectiveTestBotFormFiller

  # Fill a boostrap tabs based form
  def fill_bootstrap_tabs_form(fills = {})
    tabs = all("a[data-toggle='tab']")

    # If there's only 1 tab, just fill it out
    (fill_form_fields(fills) and return) unless tabs.length > 1

    # If there's more than one tab:
    # We first fill in all fields that are outside of the tab-content
    # Then we start at the first, and go left-to-right through all the tabs
    # clicking each one and filling any form fields found within

    active_tab = all("li.active > a[data-toggle='tab']").first

    tab_content = if active_tab && active_tab['href'].present?
      find('div' + active_tab['href']).find(:xpath, '..')
    end

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

    # If there is no visible submits, go back to the first tab
    if all(:css, "input[type='submit']").length == 0
      tabs.first.click()
      synchronize!
      save_test_bot_screenshot
    end
  end

  # Only fills in visible fields
  # fill_form(:email => 'somethign@soneone.com', :password => 'blahblah', 'user.last_name' => 'hlwerewr')
  def fill_form_fields(fills = {}, debug: false)

    save_test_bot_screenshot

    # Support for the cocoon gem
    all('a.add_fields[data-association-insertion-template],a.has_many_add').each do |field|
      next if skip_form_field?(field)

      if EffectiveTestBot.tour_mode_extreme?
        2.times { field.click(); save_test_bot_screenshot }
      else
        2.times { field.click() }; save_test_bot_screenshot
      end
    end

    all('input,select,textarea', visible: false).each do |field|
      field_name = [field.tag_name, field['type']].compact.join('_')
      skip_field_screenshot = false

      if debug
        puts "CONSIDERING #{debug_field_to_s(field)}"
        puts "  -> SKIPPED" if skip_form_field?(field)
      end

      next if skip_form_field?(field)

      value = faker_value_for_field(field, fills)

      if debug
        puts "  -> FILLING: #{value}" 
      end

      case field_name
      when 'input_text', 'input_email', 'input_password', 'input_tel', 'input_number', 'input_url', 'input_color'
        if field['class'].to_s.include?('effective_date')
          fill_input_date(field, value)
        else
          fill_input_text(field, value)
        end
      when 'input_checkbox'
        fill_input_checkbox(field, value)
      when 'input_radio'
        fill_input_radio(field, value)
      when 'textarea', 'textarea_textarea'
        fill_input_text_area(field, value)
      when 'select', 'select_select-one'
        fill_input_select(field, value)
      when 'input_file'
        fill_input_file(file, value)
      when 'input_submit', 'input_search', 'input_button'
        skip_field_screenshot = true # Do nothing
      else
        raise "unsupported field type #{field_name}"
      end

      wait_for_ajax

      if EffectiveTestBot.tour_mode_extreme?
        save_test_bot_screenshot unless skip_field_screenshot
      end
    end

    # Clear any value_for_field momoized values
    @filled_numeric_fields = nil
    @filled_password_fields = nil
    @filled_radio_fields = nil
    @filled_country_fields = nil

    save_test_bot_screenshot
  end

  def fill_input_text(field, value)
    field.set(value)
  end

  def fill_input_date(field, value)
    field.set(value)
    try_script "$('input##{field['id']}').data('DateTimePicker').hide()"
  end

  def fill_input_checkbox(field, value)
    return if value.nil?
    
    begin
      field.set(value)
    rescue => e
      label = first(:label, for: field['id'])
      label.click if label
    end
  end

  def fill_input_radio(field, value)
    return if value.nil?

    begin
      field.set(value)
    rescue => e
      label = first(:label, for: field['id'])
      label.click if label
    end
  end

  def fill_input_text_area(field, value)
    if ckeditor_text_area?(field)
      value = "<p>#{value.gsub("'", '')}</p>"
      try_script "CKEDITOR.instances['#{field['id']}'].setData('#{value}')"
    else
      field.set(value)
    end
  end

  def fill_input_select(field, value)
    if EffectiveTestBot.tour_mode_extreme? && field['class'].to_s.include?('select2') # select2
      try_script "$('select##{field['id']}').select2('open')"
      save_test_bot_screenshot
    end

    if field.all('option:enabled').length > 0 && value != :unselect
      field.select(value, match: :first, disabled: false)
    end

    if field['class'].to_s.include?('select2')
      try_script "$('select##{field['id']}').select2('close')"
    end
  end

  def fill_input_file(field, value)
    if field['class'].to_s.include?('asset-box-uploader-fileinput')
      upload_effective_asset(field, value)
    else
      field.set(value)
    end
  end

  # The field here is going to be the %input{:type => file}. Files can be one or more pathnames
  # http://stackoverflow.com/questions/5188240/using-selenium-to-imitate-dragging-a-file-onto-an-upload-element/11203629#11203629
  def upload_effective_asset(field, file)
    uid = field['id']

    # In some apps, capybara can field.set(file) and it will will just work
    # Sometimes we need to fallback to javascript to get a file uploaded
    unless ((field.set(file) || true) rescue false)
      files = Array(file)
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
    end

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

  def clear_effective_select(field)
    try_script "$('select##{field['id']}').val('').trigger('change.select2')"
  end

  private

  # Takes a capybara element
  def excluding_fields_with_parent(element, &block)
    @test_bot_excluded_fields_xpath = element.try(:path)
    yield
    @test_bot_excluded_fields_xpath = nil
  end

  def ckeditor_text_area?(field)
    return false unless field.tag_name == 'textarea'
    (field['class'].to_s.include?('ckeditor') || all("span[id='cke_#{field['id']}']").present?)
  end

  def custom_control_input?(field) # Bootstrap 4 radios and checks
    field['class'].to_s.include?('custom-control-input')
  end

  def skip_form_field?(field)
    field.reload # Handle a field changing visibility/disabled state from previous form field manipulations

    field_id = field['id'].to_s

    field_id.start_with?('datatable_') ||
    field_id.start_with?('filters_scope_') ||
    field_id.start_with?('filters_') && field['name'].blank? ||
    field.disabled? ||
    (!field.visible? && !ckeditor_text_area?(field) && !custom_control_input?(field)) ||
    ['true', true, 1].include?(field['data-test-bot-skip']) ||
    (@test_bot_excluded_fields_xpath.present? && field.path.include?(@test_bot_excluded_fields_xpath))
  end

  def debug_field_to_s(field)
    field_name = [field.tag_name, field['type']].compact.join('_')
    [field_name, ("##{field['id']}" if field['id']), (".#{field['class']}" if field['class']), field['name']].presence.join(' ')
  end

end
