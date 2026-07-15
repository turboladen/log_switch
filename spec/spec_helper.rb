# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  skip '/spec'
end

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")
require 'log_switch'
