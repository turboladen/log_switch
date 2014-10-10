require 'logger'
require_relative 'log_switch/version'

# LogSwitch allows for extending a class/module with a logger and, most
# importantly, allows for turning off logging programmatically.  See the
# +README.rdoc+ for more info.
module LogSwitch
  def self.included(base)
    @includers ||= []
    @includers << base
    base.extend ClassMethods
    base.send(:include, InstanceMethods)

    base.class_eval do
      def self.included(b)
        b.extend ClassMethods
        b.send :include, InstanceMethods
      end
    end
  end

  # Defaults to a +Logger+ writing to STDOUT.
  def self.logger
    @logger ||= ::Logger.new STDOUT
  end

  def self.logger=(new_logger)
    @logger = new_logger
  end

  # Sets back to defaults.
  def self.reset_config!
    self.logger = ::Logger.new STDOUT

    @includers.each do |klass|
      klass.logging_enabled = false
      klass.log_class_name = true
    end
  end

  module ClassMethods
    # @param value [Boolean]
    def logging_enabled
      @@logging_enabled ||= false
    end

    # Tells whether logging is turned on or not.
    #
    # @param value [Boolean]
    def logging_enabled?
      !!logging_enabled
    end

    # Use to turn logging on or off.
    #
    # @param value [Boolean]
    def logging_enabled=(value)
      @@logging_enabled = value
    end

    # @return [Symbol] The current default log level.  Starts off as :debug.
    def default_log_level
      @@default_log_level ||= :debug
    end

    # @param level [Symbol]
    def default_log_level=(level)
      @@default_log_level = level
    end

    # @return [Boolean] Tells whether logging of the class name with the log
    #   message is turned on.
    def log_class_name?
      log_class_name
    end

    def log_class_name
      @@log_class_name ||= true
    end

    # Toggle prepending the class name of the #log caller to the log message.
    def log_class_name=(value)
      @@log_class_name = value
    end

    def logger
      @@logger ||= LogSwitch.logger
    end

    def logger=(new_logger)
      @@logger = new_logger
    end

    # {#log} calls the block given to this method before it logs every time.
    # This, thus, acts as a hook in the case where you want to make sure some
    # code gets executed before you log a message.  Useful for making sure a file
    # exists before logging to it.
    #
    # @param [Proc] block The block of code to execute before logging a message
    #   with {#log}.
    def before_log=(block)
      @@before_block ||= block
    end

    def before_log
      @@before_block ||= Proc.new do; end
    end
  end

  module InstanceMethods
    def logger
      self.class.logger
    end

    # Logs a message using the level provided.  If no level provided, use
    # +@log_level+.
    #
    # @param [String] message The message to log.
    # @param [Symbol] level The log level to send to your Logger.
    def log(message, level=nil)
      level ||= self.class.default_log_level

      self.class.before_log.call
      yield if block_given?

      if self.class.logging_enabled?
        if message.respond_to? :each_line
          message.each_line do |line|
            msg = filter_class_name(line.chomp)
            logger.send(level, msg)
          end
        else
          message = filter_class_name(message)
          logger.send(level, message)
        end
      end
    end

    private

    def filter_class_name(message)
      if self.class.log_class_name?
        "<#{self.class.name}> #{message}"
      else
        message
      end
    end
  end
end
