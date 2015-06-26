module EffectiveTestBotControllerHelper
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
      when TrueClass, FalseClass, NilClass, String, Symbol, Numeric
        test_bot_assigns[key] = object
      else
        # We don't want to serialize them, but they should be present
        test_bot_assigns[key] = :present_but_not_serialized
      end
    end

    response.headers['Test-Bot-Assigns'] = Base64.encode64(test_bot_assigns.to_hash.to_json)
  end
end
