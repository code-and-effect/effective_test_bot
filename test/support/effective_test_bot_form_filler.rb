# This is all private stuff. See effective_test_bot_form_helper.rb for public DSL

require 'timeout'

module EffectiveTestBotFormFiller

  # Fill a boostrap tabs based form
  def fill_bootstrap_tabs_form(fills = {})
    tabs = all("a[data-toggle='tab']", wait: false)

    # If there's only 1 tab, just fill it out
    return fill_form_fields(fills) unless tabs.length > 1

    # If there's more than one tab:
    # We first fill in all fields that are outside of the tab-content
    # Then we start at the first, and go left-to-right through all the tabs
    # clicking each one and filling any form fields found within

    active_tab = all("li.active > a[data-toggle='tab']", wait: false).first

    tab_content = if active_tab && active_tab['href'].present?
      tab_href = '#' + active_tab['href'].split('#').last
      find('div' + tab_href).find(:xpath, '..')
    end

    excluding_fields_with_parent(tab_content) { fill_form_fields(fills) }

    # Refresh the tabs, as they may have changed
    tabs = all("a[data-toggle='tab']", wait: false)

    # Click through each tab and fill the form inside it.
    tabs.each do |tab|
      # changing the call to to fill_bootstrap_tabs_form for recursiveness should work
      # but it would be an extra all() lookup, and probably not worth it.
      tab.click()
      synchronize!
      save_test_bot_screenshot

      tab_href = '#' + tab['href'].to_s.split('#').last
      within_if('div' + tab_href) { fill_form_fields(fills) }
    end

    # If there is no visible submits, go back to the first tab
    if all("input[type='submit']", wait: false).length == 0
      tabs.first.click()
      synchronize!
      save_test_bot_screenshot
    end
  end

  # Only fills in visible fields
  # fill_form(:email => 'somethign@soneone.com', :password => 'blahblah', 'user.last_name' => 'hlwerewr')
  def fill_form_fields(fills = {})
    save_test_bot_screenshot

    debug = fills.delete(:debug)
    seen = {}

    5.times do
      # Support for the cocoon gem
      fields = all('a.add_fields[data-association-insertion-template],a.has_many_add', wait: false).reject { |field| seen[field_key(field)] }

      fields.each do |field|
        seen[field_key(field)] = true
        next if skip_form_field?(field)

        if EffectiveTestBot.tour_mode_extreme?
          2.times { field.click(); save_test_bot_screenshot }
        else
          2.times { field.click() }; save_test_bot_screenshot
        end
      end

      # Fill all fields now
      fields = all('input,select,textarea,trix-editor', visible: false).reject do |field|
        (seen[field_key(field)] rescue true)
      end

      break unless fields.present?

      fields.each do |field|
        seen[field_key(field)] = true
        skip_field_screenshot = false

        if debug
          puts "CONSIDERING: #{field_key(field)}"
          puts " -> SKIPPED" if skip_form_field?(field)
        end

        next if skip_form_field?(field)

        value = faker_value_for_field(field, fills)

        if debug
          puts " -> FILLING: #{value}"
        end

        field_name = [field.tag_name, field['type']].compact.join('_')

        case field_name
        when 'input_text', 'input_email', 'input_password', 'input_tel', 'input_number', 'input_url', 'input_color', 'input_search'
          if field['class'].to_s.include?('effective_date')
            fill_input_date(field, value)
          else
            fill_input_text(field, value)
          end
        when 'input_checkbox'
          fill_input_checkbox(field, value)
        when 'input_radio'
          fill_input_radio(field, value)
        when 'textarea', 'textarea_textarea', 'trix-editor'
          fill_input_text_area(field, value)
        when 'select', 'select_select-one', 'select_select-multiple'
          fill_input_select(field, value)
        when 'input_file'
          fill_input_file(field, value)
        when 'input_submit', 'input_button'
          skip_field_screenshot = true # Do nothing
        when 'input_hidden'
          fill_action_text_input(field, value)
        else
          raise "unsupported field type #{field_name}"
        end

        save_test_bot_screenshot if (debug || EffectiveTestBot.tour_mode_extreme?) && !skip_field_screenshot
      end

      wait_for_ajax
    end

    # Clear any value_for_field momoized values
    @filled_numeric_fields = nil
    @filled_password_fields = nil
    @filled_radio_fields = nil
    @filled_country_fields = nil

    save_test_bot_screenshot
    true
  end

  def fill_input_text(field, value)
    field.set(value)
  end

  def fill_input_date(field, value)
    field.set(value)
    try_script "$('input##{field['id']}').data('DateTimePicker').date('#{value}')"
    try_script "$('input##{field['id']}').data('DateTimePicker').hide()"
  end

  def fill_input_checkbox(field, value)
    return if [nil, false].include?(value)

    if field['class'].to_s.include?('custom-control-input')
      label = all("label[for='#{field['id']}']", wait: false).first
      return label.click() if label
    end

    begin
      field.set(value)
    rescue Exception => e
      label = all("label[for='#{field['id']}']", wait: false).first
      label.click() if label
    end
  end

  def fill_input_radio(field, value)
    return if [nil, false].include?(value)

    if field['class'].to_s.include?('custom-control-input')
      label = all("label[for='#{field['id']}']", wait: false).first
      return label.click() if label
    end

    begin
      field.set(value)
    rescue Exception => e
      label = all("label[for='#{field['id']}']", wait: false).first
      label.click() if label
    end
  end

  def fill_input_text_area(field, value)
    if ckeditor_text_area?(field)
      value = "<p>#{value.gsub("'", '')}</p>"
      try_script "CKEDITOR.instances['#{field['id']}'].setData('#{value}')"
    elsif article_editor_text_area?(field)
      value = "<p>#{value.gsub("'", '')}</p>"

      # There are weird mouse events that prevent form submission.
      try_script "ArticleEditor('##{field['id']}').stop()"
      try_script "$('textarea##{field['id']}').val('#{value}')"

      try_script "ArticleEditor('##{field['id']}').start()"
      try_script "ArticleEditor('##{field['id']}').disable()"
    else
      field.set(value)
    end
  end

  def fill_action_text_input(field, value)
    return unless action_text_input?(field)

    trix_id = field['id'].to_s.split('_trix_input_form').first
    return unless trix_id.present?

    try_script "document.querySelector(\"##{trix_id}\").editor.insertString(\"#{value}\")"
  end

  def fill_input_select(field, value)
    if EffectiveTestBot.tour_mode_extreme? && select2_input?(field)
      try_script "$('select##{field['id']}').select2('open')"
      save_test_bot_screenshot
    end

    if value == :unselect
      return close_effective_select(field)
    end

    if field.all('option:enabled', wait: false).length == 0
      return close_effective_select(field)
    end

    # Must be some options
    Array(value).each do |value|
      option = field.all("option:enabled[value=\"#{value}\"]", wait: false).first
      option ||= field.all('option:enabled', wait: false).find { |field| field.text == value }

      if option.present?
        option.select_option
      else
        # This will most likely raise an error that it cant be found
        field.select(value.to_s, match: :first, disabled: false)
      end
    end

    close_effective_select(field)
  end

  def fill_input_file(field, value)
    return if value == :unselect

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
    return unless effective_select_input?(field)
    try_script "$('select##{field['id']}').val('').trigger('change.select2')"
  end

  def close_effective_select(field)
    return unless effective_select_input?(field)
    try_script "$('select##{field['id']}').select2('close')"
  end

  def close_effective_date_time_picker(field)
    return unless effective_date_input?(field)
    # TODO
  end

  private

  # Takes a capybara element
  def excluding_fields_with_parent(element, &block)
    @test_bot_excluded_fields_xpath = element.try(:path)
    yield
    @test_bot_excluded_fields_xpath = nil
  end

  def article_editor_text_area?(field)
    field.tag_name == 'textarea' && field['class'].to_s.include?('effective_article_editor')
  end

  def ckeditor_text_area?(field)
    return false unless field.tag_name == 'textarea'
    (field['class'].to_s.include?('ckeditor') || all("span[id='cke_#{field['id']}']", wait: false).present?)
  end

  def action_text_input?(field)
    field.tag_name == 'input' && field['type'] == 'hidden' && field['id'].to_s.include?('trix_input_form')
  end

  def custom_control_input?(field) # Bootstrap 4 radios and checks
    field['class'].to_s.include?('custom-control-input')
  end

  def effective_radios_input?(field)
    field['class'].to_s.include?('effective-radios-input')
  end

  def effective_date_input?(field)
    field['class'].to_s.include?('effective_date')
  end

  def file_input?(field)
    field['type'] == 'file'
  end

  def effective_select_input?(field)
    field['class'].to_s.include?('select2') || field['class'].to_s.include?('effective_select')
  end

  def skip_form_field?(field)
    field.reload # Handle a field changing visibility/disabled state from previous form field manipulations
    field_id = field['id'].to_s

    return true if field_id.start_with?('datatable_')
    return true if field_id.start_with?('filters_scope_')
    return true if field_id.start_with?('filters_') && field['name'].blank?
    return true if field['type'] == 'button'
    return true if (field.disabled? rescue true) # Selenium::WebDriver::Error::StaleElementReferenceError: stale element reference: element is not attached to the page document
    return true if ['true', true, 1].include?(field['data-test-bot-skip'])
    return true if @test_bot_excluded_fields_xpath.present? && field.path.include?(@test_bot_excluded_fields_xpath)

    if !field.visible?
      return false if article_editor_text_area?(field)
      return false if ckeditor_text_area?(field)
      return false if custom_control_input?(field)
      return false if effective_radios_input?(field)
      return false if file_input?(field)
      return false if action_text_input?(field)
      return true
    end

    false
  end

  def field_key(field)
    field_name = [field.tag_name, field['type']].compact.join('_')

    [
      field['name'].presence,
      ("##{field['id']}" if field['id'].present?),
      field_name,
      (".#{field['class'].to_s.split(' ').join('.')}" if field['class'].present?)
    ].compact.join(' ')
  end

end
