require 'simplecov'

SimpleCov.start do
  skip "/spec"
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'log_switch'
