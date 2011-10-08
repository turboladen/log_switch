require 'simplecov'
require 'simplecov-rcov-text'

class SimpleCov::Formatter::MergedFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result)
    SimpleCov::Formatter::RcovTextFormatter.new.format(result)
  end
end

SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

SimpleCov.start do
  add_filter "/spec"
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'log_switch'
