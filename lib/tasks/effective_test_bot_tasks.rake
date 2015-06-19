require 'rake/testtask'
require 'rails/test_unit/sub_test_task'

namespace :test do
  desc 'Runs Effective Test Bot'
  task :bot do
    Rake::Task["test:effective_test_bot"].invoke
  end

  Rails::TestTask.new('effective_test_bot' => 'test:prepare') do |t|
    t.libs << 'test'
    t.test_files = FileList["#{File.dirname(__FILE__)}/../../test/test_bot/**/*_test.rb"]
  end



end

