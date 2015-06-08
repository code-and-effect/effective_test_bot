require 'rake/testtask'
require 'rails/test_unit/sub_test_task'

# namespace :test do
#   task :bot => :environment do
#     #Rails::TestTask.test_creator(Rake.application.top_level_tasks).invoke_rake_task

#     #eval File.read("#{config.root}/lib/generators/templates/effective_test_bot.rb")
#     Rails::TestTask.new('effective_test_bot' => 'test:prepare') do |t|
#       t.libs << 'test'
#       t.pattern = 'test/integration/**/*_test.rb'
#       #t.test_files = FileList["../effective_test_bot/test/**/*_test.rb"].exclude('test/controllers/**/*_test.rb')
#     end
#   end
# end

namespace :test do
  desc 'Runs Effective Test Bot'
  task :bot do
    Rake::Task["test:effective_test_bot"].invoke
  end

  #Rake::Task["db:seed"].invoke
  # Or in rails 3 add to test/test_helper.rb
  # Rails.application.load_seed

  Rails::TestTask.new('effective_test_bot' => 'test:prepare') do |t|
    puts "Read effective_test_bot rake task!"

    puts "#{File.dirname(__FILE__)}/../../test/**/*_test.rb"
    puts FileList["#{File.dirname(__FILE__)}/../../test/**/*_test.rb"]

    t.libs << 'test'
    t.test_files = FileList["#{File.dirname(__FILE__)}/../../test/**/*_test.rb"]
  end
end
