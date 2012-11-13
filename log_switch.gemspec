$:.push File.expand_path("../lib", __FILE__)
require 'log_switch/version'

Gem::Specification.new do |s|
  s.name = "log_switch"
  s.version = LogSwitch::VERSION
  s.authors = ["Steve Loveless"]
  s.homepage = %q(http://github.com/turboladen/log_switch)
  s.email = %w(steve.loveless@gmail.com)
  s.summary = %q(Extends a class for singleton style logging that can easily be
                 turned on and off.)
  s.description = %q(Extends a class for singleton style logging that can 
                     easily be turned on and off.)

  s.required_rubygems_version = ">=1.8.0"
  s.files = Dir.glob("{lib,spec}/**/*") +
    Dir.glob("*.rdoc") +
    %w(.gemtest Gemfile log_switch.gemspec Rakefile)

  s.test_files = Dir.glob("{spec}/**/*")
  s.require_paths = %w(lib)

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", ">= 2.6.0"

  if RUBY_VERSION > '1.9'
    s.add_development_dependency "simplecov"

    if defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
      s.add_development_dependency("tailor", ">=1.1.2")
    end
  end

  s.add_development_dependency "yard", ">= 0.7.2"
end

