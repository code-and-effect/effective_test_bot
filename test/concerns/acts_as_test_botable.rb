module ActsAsTestBotable
  extend ActiveSupport::Concern

  module ActionDispatch
    CRUD_ACTIONS = [:new, :create, :edit, :update, :index, :show, :destroy]

    def crud_test(obj, user, options = {})
      puts "crud_test called with user #{user.email}"

      # Check for expected usage
      unless (obj.kind_of?(Class) || obj.kind_of?(ActiveRecord::Base)) && user.kind_of?(User) && options.kind_of?(Hash)
        puts 'invalid parameters passed to crud_test(), expecting crud_test(Post || Post.new(), User.first, options_hash)' and return
      end

      # Make sure Obj.new() works
      if obj.kind_of?(Class) && (obj.new() rescue false) == false
        puts "effective_test_bot: failed to initialize object with #{obj}.new(), unable to proceed" and return
      end

      # Parse the resource and resource class
      resource = obj.kind_of?(Class) ? obj.new() : obj
      resource_class = obj.kind_of?(Class) ? obj : obj.class

      # If obj is an ActiveRecord object with attributes, Post.new(:title => 'My Title')
      # then compute any explicit attributes, so forms will be filled with those values
      resource_attributes = if obj.kind_of?(ActiveRecord::Base)
        empty = resource_class.new()
        {}.tap { |atts| resource.attributes.each { |k, v| atts[k] = v if empty.attributes[k] != v } }
      end || {}

      # Final options to call each test with
      test_lets = {
        resource: resource,
        resource_class: resource_class,
        resource_name: resource_class.name.underscore,
        resource_attributes: resource_attributes,
        controller_namespace: options[:namespace],
        user: user
      }

      # Set up the crud_actions_to_test
      test_actions = if options[:only]
        CRUD_ACTIONS & Array(options[:only]).flatten.compact.map(&:to_sym)
      elsif options[:except]
        CRUD_ACTIONS - Array(options[:except]).flatten.compact.map(&:to_sym)
      else
        CRUD_ACTIONS
      end

      # Define the methods to actually call
      test_actions.each do |action|
        case action
        when :new
          define_method("test_bot: #new #{user.email}") { run_test_bot_test(:new, test_lets) }
        when :create
        end
      end
    end
  end

  # included do
  #   test_lets = @test_lets.dup

  #   @test_actions.each do |action|
  #     case action
  #     when :new
  #       define_method('test_bot: #new') { run_test_bot_test(:new, test_lets) }
  #     when :create
  #       define_method('test_bot: #create valid') { run_test_bot_test(:create_valid, test_lets) }
  #     end
  #   end
  # end

  def run_test_bot_test(test, options = {})
    puts "RUN TEST BOT TEST CALLED #{options.keys.inspect}"

    options.each { |k, v| self.class.let(k) { v } }
    self.send(test)
  end

end
