# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'
require 'rubocop/rake_task'

YARD::Rake::YardocTask.new do |t|
  t.files = %w[lib/**/*.rb - CHANGELOG.md]
  t.options = %W[--title log_switch Documentation (#{LogSwitch::VERSION})]
  t.options += %w[--main README.md]
end

RSpec::Core::RakeTask.new do |t|
  t.ruby_opts = %w[-w]
end

RuboCop::RakeTask.new

# RuboCop covers Ruby; dprint covers the Markdown and YAML. It is a binary
# rather than a gem, so `bundle install` cannot supply it -- fail loudly with
# somewhere to go rather than skipping, which would make the gate a no-op
# exactly when nobody notices.
desc 'Check non-Ruby formatting with dprint'
task :dprint do
  abort <<~MSG unless system('command -v dprint > /dev/null 2>&1')
    dprint is not installed, so Markdown/YAML formatting was not checked.
    Install it (https://dprint.dev/install/) -- e.g. `brew install dprint` --
    or run `rake spec rubocop` to skip this deliberately.
  MSG

  sh 'dprint check'
end

desc 'Format non-Ruby files with dprint'
task 'dprint:fmt' do
  sh 'dprint fmt'
end

task test: %i[spec rubocop dprint]

task default: :test
