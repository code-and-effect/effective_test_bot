module EffectiveTestBot
  module DSL
    extend ActiveSupport::Concern

    included do
      # test/support/
      include EffectiveTestBotAssertions
      include EffectiveTestBotFormFaker
      include EffectiveTestBotFormFiller
      include EffectiveTestBotFormHelper
      include EffectiveTestBotLoginHelper
      include EffectiveTestBotMinitestHelper
      include EffectiveTestBotScreenshotsHelper
      include EffectiveTestBotTestHelper

      class BasicObject
        include EffectiveTestBotMocks
      end

      # test/test_botable/
      include BaseTest
      include CrudTest
      include DeviseTest
      include MemberTest
      include PageTest
      include RedirectTest
      include WizardTest

      # test/concerns/test_botable/
      include TestBotable::BaseDsl
      include TestBotable::CrudDsl
      include TestBotable::DeviseDsl
      include TestBotable::MemberDsl
      include TestBotable::PageDsl
      include TestBotable::RedirectDsl
      include TestBotable::WizardDsl
    end

    def absolute_image_path
      Rails.root.join("tmp/screenshots/#{image_name.gsub('/', '-')}.png")
    end

  end
end
