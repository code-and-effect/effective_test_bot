module EffectiveTestBotControllerHelper
  def assign_test_bot_http_headers
    response.headers['Flash'] = Base64.encode64(flash.to_hash.to_json)
  end
end
