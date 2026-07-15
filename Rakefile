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

task test: %i[spec rubocop]

task default: :test
