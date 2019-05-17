module TestSeedable
  module Seed
    extend ActiveSupport::Concern

    module ClassMethods
      def seeds(seed = :all)
        raise 'unexpected argument. try :all, :db, :test' unless [:all, :db, :test].include?(seed)

        ActiveSupport::TestCase.class_eval do
          case seed
          when :all
            def before_setup
              @@_loaded_test_fixtures_seeds ||= load_fixtures_seeds(:all); super
            end
          when :db
            def before_setup
              @@_loaded_test_fixtures_seeds ||= load_fixtures_seeds(:db); super
            end
          when :test
            def before_setup
              @@_loaded_test_fixtures_seeds ||= load_fixtures_seeds(:test); super
            end
          end
        end
      end
    end

    # Instance Methods
    def load_fixtures_seeds(seed = :all)
      db_seeds = "#{Rails.root}/db/seeds.rb"
      test_seeds = "#{Rails.root}/test/fixtures/seeds.rb"

      case seed
      when :all
        load(db_seeds) if File.exists?(db_seeds)
        load(test_seeds) if File.exists?(test_seeds)
      when :db
        load(db_seeds) if File.exists?(db_seeds)
      when :test
        load(test_seeds) if File.exists?(test_seeds)
      else
        raise('unexpected seed argument. use :all, :db or :test')
      end

      true
    end
  end
end
