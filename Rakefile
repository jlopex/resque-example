require 'bundler/setup'
require "resque/tasks"
require 'resque'
require 'rake/testtask'
require File.expand_path(File.dirname(__FILE__) + '/lib/job')

task :default => [:test]

Rake::TestTask.new(:test) do |tsk|
  tsk.test_files = FileList['test/*_test.rb']
end
