# rake test:bot
# rake test:bot TEST=documents#new
# rake test:bot TEST=documents#new,documents#show
# rake test:bot TOUR=true
# rake test:bot TOUR=verbose   # Prints out the animated gif patch after test is run
# rake test:bot TOUR=extreme   # Makes a whole bunch of extra screenshots

# rake test:bot:tour
# rake test:bot:tour TEST=documents#new

# rake test:bot:environment
# rake test:bot:purge

# rake test:bot:tours
# rake test:bot:tours TEST=documents

# rake test:tour  # Not the bot, just regular minitest 'rake test'
# rake test:tourv

namespace :test do
  desc 'Runs the effective_test_bot automated test suite'
  task :bot do
    if ENV['TEST'].present?
      ENV['TEST_BOT_TEST'] = ENV['TEST']
      ENV['TEST'] = nil
    end

    system("rails test #{File.dirname(__FILE__)}/../../test/test_bot/system/application_test.rb")
  end

  desc "Runs 'rake test' with effective_test_bot tour mode enabled"
  task :tour do
    ENV['TOUR'] ||= 'true'
    Rake::Task['test'].invoke
  end

  desc "Runs 'rake test' with effective_test_bot verbose tour mode enabled"
  task :tourv do
    ENV['TOUR'] ||= 'verbose'
    Rake::Task['test'].invoke
  end

  namespace :bot do
    desc 'Runs effective_test_bot environment test'
    task :environment do
      system("rails test #{File.dirname(__FILE__)}/../../test/test_bot/system/environment_test.rb")
    end

    desc 'Deletes all effective_test_bot temporary, failure and tour screenshots'
    task :purge do
      FileUtils.rm_rf(Rails.root + 'test/tours')
      FileUtils.rm_rf(Rails.root + 'tmp/test_bot')
      puts "Successfully purged all effective_test_bot screenshots"
    end

    desc 'Runs effective_test_bot environment test in tour mode'
    task :tour do
      ENV['TOUR'] ||= 'true'
      Rake::Task['test:bot'].invoke
    end

    desc 'Runs effective_test_bot environment test in verbose tour mode'
    task :tourv do
      ENV['TOUR'] ||= 'verbose'
      Rake::Task['test:bot'].invoke
    end

    desc 'Prints all effective_test_bot animated gif tour file paths'
    task :tours do
      present = false
      Dir['test/tours/*.gif'].each do |file|
        file = file.to_s

        if ENV['TEST'].present?
          next unless file.include?(ENV['TEST'])
        end

        present = true
        puts "\e[32m#{Rails.root + file}\e[0m" # 32 is green
      end

      puts 'No effective_test_bot tours present.' unless present
    end

    desc 'Runs effective_test_bot while skipping all previously passed tests'
    task :fails do
      ENV['FAILS'] ||= 'true'
      Rake::Task['test:bot'].invoke
    end

    desc 'Runs effective_test_bot while skipping all previously passed tests upto the first failure'
    task :fail do
      ENV['FAILS'] ||= 'true'
      ENV['FAIL_FAST'] ||= 'true'
      Rake::Task['test:bot'].invoke
    end

    desc 'Runs effective_test_bot while skipping all previously passed tests'
    task :failed do
      ENV['FAILS'] ||= 'true'
      Rake::Task['test:bot'].invoke
    end

  end # /namespace bot

  desc 'loads test/fixtures/seeds.rb'
  task load_fixture_seeds: :environment do
    seeds = "#{Rails.root}/test/fixtures/seeds.rb"

    if File.exist?(seeds)
      puts 'loading fixture seed'
      load(seeds)
    end
  end

end
