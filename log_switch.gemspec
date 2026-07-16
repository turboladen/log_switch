# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'log_switch/version'

Gem::Specification.new do |s|
  s.name = 'log_switch'
  s.version = LogSwitch::VERSION
  s.authors = ['Steve Loveless']
  s.homepage = 'https://github.com/turboladen/log_switch'
  s.email = %w[steve.loveless@gmail.com]
  s.summary = 'Extends a class for singleton style logging that can easily be turned on and off.'
  s.description = 'Mixes a shared logger into a class or module and toggles its logging on and off programmatically.'

  s.license = 'Unlicense'
  s.required_ruby_version = '>= 3.3'

  s.metadata = {
    'source_code_uri' => 'https://github.com/turboladen/log_switch',
    'changelog_uri' => "https://github.com/turboladen/log_switch/blob/v#{LogSwitch::VERSION}/CHANGELOG.md",
    'rubygems_mfa_required' => 'true'
  }

  s.files = Dir.glob('lib/**/*').select { |f| File.file?(f) } +
            %w[CHANGELOG.md LICENSE README.md log_switch.gemspec]

  s.require_paths = %w[lib]

  s.add_dependency 'logger', '~> 1.5'

  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.13'
  s.add_development_dependency 'rubocop', '~> 1.88'
  s.add_development_dependency 'simplecov', '~> 1.0'
  s.add_development_dependency 'yard', '~> 0.9'
end
