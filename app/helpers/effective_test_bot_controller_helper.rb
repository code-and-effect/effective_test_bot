module EffectiveTestBotControllerHelper
  # This is included as an after_filter
  def assign_test_bot_http_headers
    response.headers['Test-Bot-Flash'] = Base64.encode64(flash.to_hash.to_json)

    # Assign the Assigns now
    # With the assigns, we're a little bit more selective
    # Anything that's a simple object can be serialized
    test_bot_assigns = {}

    view_assigns.each do |key, object|
      case object
      when ActiveRecord::Base
        test_bot_assigns[key] = object.attributes
        test_bot_assigns[key][:errors] = object.errors.messages.delete_if { |_, v| v.blank? } if object.errors.present?
      when (ActiveModel::Model rescue nil)
        test_bot_assigns[key] = object.respond_to?(:attributes) ? object.attributes : {present_but_not_serialized: true}
        test_bot_assigns[key][:errors] = object.errors.messages.delete_if { |_, v| v.blank? } if object.errors.present?
      when TrueClass, FalseClass, NilClass, String, Symbol, Numeric
        test_bot_assigns[key] = object
      else
        # We don't want to serialize them, but they should be present
        test_bot_assigns[key] = :present_but_not_serialized
      end
    end

    response.headers['Test-Bot-Assigns'] = Base64.encode64(test_bot_assigns.to_hash.to_json)
  end

  # We get here if ApplicationController raised a ActionController::UnpermittedParameters error
  def assign_test_bot_unpermitted_params_header(exception)
    if exception.kind_of?(ActionController::UnpermittedParameters)
      response.headers['Test-Bot-Unpermitted-Params'] = Base64.encode64(exception.params.to_json)
    end
  end

  def assign_test_bot_access_denied_exception(exception)
    return unless Rails.env.test?

    response.headers['Test-Bot-Access-Denied'] = Base64.encode64({
      exception: exception,
      action: exception.action,
      subject: (
        if exception.subject.kind_of?(Symbol)
          ":#{exception.subject}"
        elsif exception.subject.class == Class
          exception.subject.name
        else
          exception.subject.class.name
        end
      )
    }.to_json)
  end

end
