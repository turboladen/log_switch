require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'tailor/rake_task'
require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files = %w(lib/**/*.rb - History.rdoc)
  t.options = %w(--title log_switch Documentation (#{LogSwitch::VERSION}))
  t.options += %w(--main README.rdoc)
end

RSpec::Core::RakeTask.new do |t|
  t.ruby_opts = %w(-w)
end

Tailor::RakeTask.new do |task|
  task.file_set 'lib/**/*.rb'
  task.file_set 'spec/**/*.rb', :specs
end

# Alias for rubygems-test
task :test => :spec

task :default => :install

