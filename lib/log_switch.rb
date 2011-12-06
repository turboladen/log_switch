require File.expand_path(File.dirname(__FILE__) + '/log_switch/version')
require "logger"

# LogSwitch allows for extending a class/module with a logger and, most
# importantly, allows for turning off logging programmatically.  See the
# +README.rdoc+ for more info.
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

  # +#log+ calls the block given to this method before it logs every time.
  # This, thus, acts as a hook in the case where you want to make sure some
  # code gets executed before you log a message.  Useful for making sure a file
  # exists before logging to it.
  #
  # @param [Proc] block The block of code to execute before logging a message
  #   with +#log+.
  def before(&block)
    @before_block = block
  end

  # Logs a message using the level provided.  If no level provided, use
  # +@log_level+.
  #
  # @param [String] message The message to log.
  # @param [Symbol] level The log level to send to your Logger.
  def log(message, level=log_level)
    @before_block.call unless @before_block.nil?
    yield if block_given?
    message.each_line { |line| logger.send level, line.chomp if log? }
  end

  # Sets back to defaults.
  def reset_config!
    self.log = true
    self.logger = ::Logger.new STDOUT
    self.log_level = :debug
  end
end
