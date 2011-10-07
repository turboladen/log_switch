require_relative 'log_switch/version'
require "logger"

# FIX Document me!
module LogSwitch

  # Use to turn logging on or off.
  attr_writer :log

  # Tells whether logging is turned on or not.
  def log?
    @log != false
  end

  # Set this to the Logger you want to use.
  attr_writer :logger

  # Defaults to a +Logger+ writing to STDOUT.
  def logger
    @logger ||= ::Logger.new STDOUT
  end

  # Set the log level so you don't have to pass it in on your call.
  attr_writer :log_level

  # @return [Symbol] The current default log level.  Starts off as :debug.
  def log_level
    @log_level ||= :debug
  end

  # Logs a message using the level provided.  If no level provided, use
  # +@log_level+.
  def log(message, level=log_level)
    message.each_line { |line| logger.send level, line.chomp if log? }
  end
end
