module EffectiveTestBot
  class Command
    def initialize(args = {})
      @options = {
        :pid_dir => "#{Rails.root}/tmp/pids",
        :pid_file => "#{Rails.root}/tmp/pids/effective_test_bot.pid"
      }
    end

    def start
      Dir.mkdir(@options[:pid_dir]) unless File.exists?(@options[:pid_dir])

      # Also check how this process was called.  Don't run on delayed_job kind athing
      puts "EffectiveTestBot started with parent process #{Process.argv0}"

      # Only run the EffectiveTestBot if we are running as a server
      if ['rails', 'ruby_executable_hooks'].none? { |cmd| Process.argv0.end_with?(cmd) }
        puts 'EffectiveTestBot skipping run.  Exitting.'
        exit 1
      end

      file = File.new(@options[:pid_file], 'w')
      mutex = file.flock(File::LOCK_EX|File::LOCK_NB)

      if mutex == false
        puts "EffectiveTestBot already run.  Exitting."
        exit 1
      end

      at_exit do
        (File.delete(@options[:pid_file]) rescue true)
      end

      begin
        EffectiveTestBot::Worker.new().start
      rescue => e
        Rails.logger.fatal e
        STDERR.puts e.message
        exit 1
      end
    end
  end
end
