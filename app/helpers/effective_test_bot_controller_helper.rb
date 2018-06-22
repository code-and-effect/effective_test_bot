module EffectiveTestBotControllerHelper
  BODY = '</body>'

  # This is included as an after_action in the controller
  def assign_test_bot_payload(payload = {})
    return unless response.content_type == 'text/html'.freeze
    return unless !!(response.body[BODY])

    payload.merge!({ response_code: response.code, assigns: test_bot_view_assigns, flash: flash.to_hash })

    payload = view_context.content_tag(:script, id: 'test_bot_payload') do
      [
        '',
        'window.effective_test_bot = {};',
        payload.map { |k, v| "window.effective_test_bot.#{k} = #{v.respond_to?(:to_json) ? v.to_json : ("'" + v + "'")};" },
        '',
      ].join("\n").html_safe
    end

    split = response.body.split(BODY)
    response.body = "#{split.first}#{payload}#{BODY}#{split.last if split.size > 1}"
  end

  # This is called in an ActionController rescue_from.
  def assign_test_bot_access_denied_exception(exception)
    assign_test_bot_payload(test_bot_access_denied(exception))
  end

  private

  def test_bot_access_denied(exception)
    {
      access_denied: exception,
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
    }
  end

  def test_bot_view_assigns
    assigns = {}

    view_assigns.each do |key, object|
      case object
      when ActiveRecord::Base
        assigns[key] = object.attributes
        assigns[key][:errors] = object.errors.messages.delete_if { |_, v| v.blank? } if object.errors.present?
      when (ActiveModel::Model rescue nil)
        assigns[key] = object.respond_to?(:attributes) ? object.attributes : { present_but_not_serialized: true }
        assigns[key][:errors] = object.errors.messages.delete_if { |_, v| v.blank? } if object.errors.present?
      when TrueClass, FalseClass, NilClass, String, Symbol, Numeric
        assigns[key] = object
      else
        # We don't want to serialize them, but they should be present
        assigns[key] = :present_but_not_serialized
      end
    end

    assigns
  end

end
