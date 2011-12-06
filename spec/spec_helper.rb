if RUBY_VERSION > '1.9'
  require 'simplecov'

  class SimpleCov::Formatter::MergedFormatter
    def format(result)
      SimpleCov::Formatter::HTMLFormatter.new.format(result)
    end
  end

  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

  SimpleCov.start do
    add_filter "/spec"
  end
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'log_switch'
