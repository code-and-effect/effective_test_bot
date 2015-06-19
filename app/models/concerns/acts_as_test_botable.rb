module ActsAsTestBotable
  extend ActiveSupport::Concern

  module ClassMethods
    def crud_test(klass, user)
      include ::CrudTest
      let(:user) { user }

      # This will run any CrudTest methods, in order, as it's defined in the file
      # Then the rest of the methods in whatever order they occur originally (:random, :alpha, :sorted)
      def self.runnable_methods
        ::CrudTest.public_instance_methods.map { |name| name.to_s if name.to_s.starts_with?('test_bot') }.compact + super.select { |name| !name.starts_with?('test_bot') }
      end
    end

  end
end
