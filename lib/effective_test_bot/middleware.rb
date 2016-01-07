# Watch for any rails server exceptions and write the stacktrace to ./tmp/test_bot/exception.txt
# This file is checked for by assert_no_exceptions

module EffectiveTestBot
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        @app.call(env)
      rescue Exception => exception
        begin
          save(exception)
        rescue => e
          puts "TestBotError: An error occurred while attempting to save a rails server exception: #{e.message}"
        end

        raise exception
      end
    end

    def save(exception)
      lines = [exception.message] + exception.backtrace.first(8)

      dir = File.join(Dir.pwd, 'tmp', 'test_bot')
      file = File.join(dir, 'exception.txt')

      Dir.mkdir(dir) unless File.exists?(dir)
      File.delete(file) if File.exists?(file)

      File.open(file, 'w') do |file|
        file.write "================== Start server exception ==================\n"
        lines.each { |line| file.write(line); file.write("\n") }
        file.write "=================== End server exception ===================\n"
      end
    end
  end
end
