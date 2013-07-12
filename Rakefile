#!/usr/bin/env rake
require "bundler/gem_tasks"
 
require 'rake/testtask'
 
Rake::TestTask.new do |t|
  t.libs << 'lib/active_model/json/schema'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
 
task :default => :test
