require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files = %w(lib/**/*.rb - History.rdoc)
  t.options = %W(--title log_switch Documentation (#{LogSwitch::VERSION}))
  t.options += %w(--main README.rdoc)
end

RSpec::Core::RakeTask.new do |t|
  t.ruby_opts = %w(-w)
end

if RUBY_ENGINE == "ruby" && RUBY_VERSION > "1.9"
  require 'tailor/rake_task'

  Tailor::RakeTask.new do |task|
    task.file_set 'lib/**/*.rb'
    task.file_set 'spec/**/*.rb', :specs
  end

# Alias for rubygems-test
  task :test => [:spec, :tailor]
else
  task :test => :spec
end

task :default => :test
