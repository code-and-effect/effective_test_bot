
module EffectiveTestBot
  class Worker
    def initialize(options = {})
    end

    def start
      trap('TERM') do
        Thread.new { say 'Exiting...' } and stop
      end

      trap('INT') do
        Thread.new { say 'Exiting...' } and stop
      end

      say 'Starting EffectiveTestBot'

      count = 10

      loop do
        # Run each recipe
        say "This is a command"
        say User.count
        sleep(1)
        break if stop?

        count = count - 1

        break if count <= 0
      end
    end

    def stop
      @exit = true
    end

    def stop?
      !!@exit
    end

    def say(content)
      puts content
      Rails.logger.info content
    end

  end
end
