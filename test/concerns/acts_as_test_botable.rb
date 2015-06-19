module ActsAsTestBotable
  extend ActiveSupport::Concern

  module ClassMethods
    CRUD_ACTIONS = [:index, :new, :create, :edit, :update, :show, :destroy]

    def crud_test(obj, user, options = {})
      # Check for expected usage
      unless (obj.kind_of?(Class) || obj.kind_of?(ActiveRecord::Base)) && user.kind_of?(User) && options.kind_of?(Hash)
        puts 'invalid parameters passed to crud_test(), expecting crud_test(Post || Post.new(), User.first, options_hash)' and return
      end

      # Make sure Obj.new() works
      if obj.kind_of?(Class) && (obj.new() rescue false) == false
        puts "effective_test_bot: failed to initialize object with #{obj}.new(), unable to proceed" and return
      end

      # Set up the crud_actions_to_test
      crud_actions_to_test = if options[:only]
        Array(options[:only]).flatten.compact.map(&:to_sym)
      elsif options[:except]
        (CRUD_ACTIONS - Array(options[:except]).flatten.compact.map(&:to_sym))
      else
        CRUD_ACTIONS
      end

      # Parse the resource and resourece class
      resource = obj.kind_of?(Class) ? obj.new() : obj
      resource_class = obj.kind_of?(Class) ? obj : obj.class

      # If obj is an ActiveRecord object with attributes, Post.new(:title => 'My Title')
      # then compute any explicit attributes, so forms will be filled with those values
      resource_attributes = if obj.kind_of?(ActiveRecord::Base)
        empty = resource_class.new()
        {}.tap { |atts| resource.attributes.each { |k, v| atts[k] = v if empty.attributes[k] != v } }
      end || {}

      # Assign variables to be used in test/test_botable/crud_test.rb
      let(:resource) { resource }
      let(:resource_class) { resource_class }
      let(:resource_name) { resource_class.name.underscore }
      let(:resource_attributes) { resource_attributes }
      let(:user) { user }
      let(:controller_namespace) { options[:namespace] }
      let(:crud_actions_to_test) { crud_actions_to_test }

      include ::CrudTest

      # This will run any CrudTest methods, in order, as it's defined in the file
      # Then the rest of the methods in whatever order they occur originally (:random, :alpha, :sorted)
      def self.runnable_methods
        ::CrudTest.public_instance_methods.map { |name| name.to_s if name.to_s.starts_with?('test_bot') }.compact + super.select { |name| !name.starts_with?('test_bot') }
      end
    end

  end
end
