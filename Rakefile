require 'rspec/core/rake_task'
require "pry"

RSpec::Core::RakeTask.new do |task|
  task.pattern = Dir['test/*_spec.rb']
  task.rspec_opts = ['--color -f d']
end

desc "Set up the load paths"
task :load_path do
  dir = File.dirname(__FILE__)
  $:.unshift(File.join(dir, "lib"))
end

desc "Run a console"
task :console => :load_path do
  require "lang/interpreter"
  require "engine/engine"
  pry
end
