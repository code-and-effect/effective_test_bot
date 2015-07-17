# This DSL gives a class level and an instance level way of calling specific test suite
#
# class PostsTest < ActionDispatch::IntegrationTest
#   page_test(:posts_path, User.first)
#
#   test 'a one-off action' do
#     page_action_test(:posts_path, User.first)
#   end
# end


module TestBotable
  module PageDsl
    extend ActiveSupport::Concern

    module ClassMethods

      def page_test(path, user, options = {})
        test_name = test_bot_test_name('page_test', options.delete(:label) || path)
        define_method(test_name) { page_action_test(path, user, options) }
      end

    end

    # Instance Methods - Call me from within a test
    def page_action_test(path, user, options = {})
      begin
        self.class.parse_test_bot_options(options.merge(user: user, page_path: path))
      rescue => e
        raise "Error: #{e.message}.  Expected usage: page_test(:about_path, User.first, options_hash)"
      end.each { |k, v| self.class.let(k) { v } } # Using the regular let(:foo) { 'bar' } syntax

      self.send(:test_bot_page_test)
    end

  end
end
