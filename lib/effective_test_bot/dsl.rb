module EffectiveTestBot
  module DSL
    extend ActiveSupport::Concern

    included do
      include EffectiveTestBotAssertions
      include EffectiveTestBotFormHelper
      include EffectiveTestBotFormFiller
      include EffectiveTestBotLoginHelper
      include EffectiveTestBotMinitestHelper
      include EffectiveTestBotScreenshotsHelper
      include EffectiveTestBotTestHelper

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
  end
end
