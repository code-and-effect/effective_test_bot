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

      puts "EffectiveTestBot started with #{Process.argv0}"

      puts "DEFINED? #{defined?(Rails::Console)}"

      if defined?(Rails::Console)
        puts 'EffectiveTestBot skipping run.  Process is not a server.'
        exit 1
      end

      # Only run the EffectiveTestBot if we are running as a server
      if ['rails', 'ruby_executable_hooks', 'unicorn'].none? { |cmd| Process.argv0.end_with?(cmd) }
        puts "EffectiveTestBot skipping run.  Process argv0 not in whitelist.  Started with #{Process.argv0}"
        exit 1
      end

      file = File.new(@options[:pid_file], 'w')
      mutex = file.flock(File::LOCK_EX|File::LOCK_NB)

      if mutex == false
        puts "EffectiveTestBot skipping run.  Already run.  Unable to get exclusive lock on #{@options[:pid_file]}"
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
