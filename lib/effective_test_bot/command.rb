module EffectiveTestBot
  class Command
    def initialize(args)
      @options = {:pid_dir => "#{Rails.root}/tmp/pids"}
    end

    def start
      Dir.mkdir(@options[:pid_dir]) unless File.exists?(@options[:pid_dir])

      begin
        Dir.chdir(Rails.root)

        # Delayed::Worker.after_fork
        # Delayed::Worker.logger ||= Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

        worker = EffectiveTestBot::Worker.new(@options)
        worker.start
      rescue => e
        Rails.logger.fatal e
        STDERR.puts e.message
        exit 1
      end
    end
  end
end
