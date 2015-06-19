module ActsAsTestBotable
  extend ActiveSupport::Concern

  module ClassMethods
    def crud_test(resource_class, user, *namespace)
      let(:namespace) { namespace }
      let(:user) { user }

      let(:resource_class) { resource_class }
      let(:resource_name) { resource_class.name.underscore }
      let(:resource) { resource_class.new() }

      if resource_class.ancestors.include?(ActiveRecord::Base) == false
        puts "effective_test_bot: crud_test() first argument must be an ActiveRecord object"
        return
      elsif user.kind_of?(User) == false
        puts "effective_test_bot: crud_test() second argument must be a User object"
        return
      elsif ((resource_class.new().kind_of?(resource_class) == false) rescue true)
        puts "effective_test_bot: failed to call #{resource_class}.new(), unable to proceed"
        return
      end

      include ::CrudTest

      # This will run any CrudTest methods, in order, as it's defined in the file
      # Then the rest of the methods in whatever order they occur originally (:random, :alpha, :sorted)
      def self.runnable_methods
        ::CrudTest.public_instance_methods.map { |name| name.to_s if name.to_s.starts_with?('test_bot') }.compact + super.select { |name| !name.starts_with?('test_bot') }
      end
    end

  end
end
