# EffectiveTestBot Rails Engine

if Rails.env.test?
  EffectiveTestBot.setup do |config|
    config.screenshots = true
  end
end
