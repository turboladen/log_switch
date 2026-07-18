# frozen_string_literal: true

require 'logger'
require_relative 'log_switch/version'

# LogSwitch mixes a logger into a class/module and, most importantly, allows for
# turning off logging programmatically.  See README.md for more info.
#
# Configuration is per-includer with live inheritance: an includer reads each
# setting from its parent in the include chain (up to the library defaults)
# until it assigns its own value, at which point the write shadows the parent
# locally without affecting the parent or any sibling includer.
module LogSwitch
  # The singleton instance variables that hold per-includer configuration.
  # {reset_config!} clears these to restore fall-through to the defaults; note
  # +@log_switch_parent+ is structural and is deliberately not in this list.
  CONFIG_VARIABLES = %i[
    @logging_enabled
    @default_log_level
    @log_class_name
    @logger
    @before_block
  ].freeze

  def self.included(base)
    register_includer(base, nil)
  end

  # Extends +includer+ with the config/instance API and records +parent+ as the
  # next link in its config fall-through chain (+nil+ for a direct includer,
  # whose reads fall through to the library defaults).
  #
  # +includer+ is held weakly in +@includers+ (an +ObjectSpace::WeakMap+ keyed
  # by the includer, so it can be garbage-collected) purely so {reset_config!}
  # can find it; key identity de-duplicates re-registration. Re-registering an
  # existing includer is idempotent -- it re-points the parent link and re-runs
  # the (idempotent) extend/include/hook setup.
  def self.register_includer(includer, parent)
    (@includers ||= ObjectSpace::WeakMap.new)[includer] = true
    includer.instance_variable_set(:@log_switch_parent, parent)
    includer.extend ClassMethods
    includer.send(:include, InstanceMethods)
    define_cascade_hooks(includer)
  end

  # Redefines +self.included+ and +self.inherited+ on +includer+ so the mixin
  # cascades to arbitrary depth through both paths: including a LogSwitch-including
  # module elsewhere, and subclassing an includer, each propagate the method sets
  # and the parent link (a subclass's parent is its superclass, giving it the same
  # live config fall-through). A consequence is that an intermediate class or module
  # defining its own +self.included+ or +self.inherited+ is unsupported -- these
  # redefinitions shadow it.
  def self.define_cascade_hooks(includer)
    includer.class_eval do
      def self.included(other)
        LogSwitch.register_includer(other, self)
      end

      def self.inherited(subclass)
        super
        LogSwitch.register_includer(subclass, self)
      end
    end
  end

  # Defaults to a +Logger+ writing to +$stdout+.
  def self.logger
    @logger ||= ::Logger.new $stdout
  end

  def self.logger=(new_logger)
    @logger = new_logger
  end

  # Sets back to defaults by clearing every includer's local config, so reads
  # fall through to the library defaults again.
  def self.reset_config!
    self.logger = ::Logger.new $stdout

    (@includers ||= ObjectSpace::WeakMap.new).each_key do |includer|
      CONFIG_VARIABLES.each do |ivar|
        includer.send(:remove_instance_variable, ivar) if includer.instance_variable_defined?(ivar)
      end
    end
  end

  # Per-includer configuration API mixed onto each includer as class methods.
  module ClassMethods
    # Shared no-op default for {#before_log}, so an unconfigured hook costs no
    # per-call allocation when {#log} invokes +before_log.call+.
    NULL_HOOK = proc {}

    # @param value [Boolean]
    def logging_enabled
      read_config(:@logging_enabled, :logging_enabled) { false }
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
      @logging_enabled = value
    end

    # @return [Symbol] The current default log level.  Starts off as :debug.
    def default_log_level
      read_config(:@default_log_level, :default_log_level) { :debug }
    end

    # @param level [Symbol]
    def default_log_level=(level)
      @default_log_level = level
    end

    # @return [Boolean] Tells whether logging of the class name with the log
    #   message is turned on.
    def log_class_name?
      log_class_name
    end

    def log_class_name
      read_config(:@log_class_name, :log_class_name) { true }
    end

    # Toggle prepending the class name of the #log caller to the log message.
    def log_class_name=(value)
      @log_class_name = value
    end

    def logger
      read_config(:@logger, :logger) { LogSwitch.logger }
    end

    def logger=(new_logger)
      @logger = new_logger
    end

    # {#log} calls the block given to this method before it logs every time.
    # This, thus, acts as a hook in the case where you want to make sure some
    # code gets executed before you log a message.  Useful for making sure a file
    # exists before logging to it.
    #
    # @param [Proc] block The block of code to execute before logging a message
    #   with {#log}.
    def before_log=(block)
      @before_block = block
    end

    def before_log
      read_config(:@before_block, :before_log) { NULL_HOOK }
    end

    private

    # Reads a config value with live fall-through: the includer's own value if
    # set, else the parent's (which applies its own fall-through, composing to
    # any depth), else the library default from the block.
    def read_config(ivar, reader)
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)

      parent = @log_switch_parent
      return parent.public_send(reader) if parent

      yield
    end
  end

  # Instance-level logging API (#log and its helpers) mixed into each includer.
  module InstanceMethods
    def logger
      self.class.logger
    end

    # Logs a message using the level provided.  If no level provided, use
    # the class's +default_log_level+.
    #
    # @param [String] message The message to log.
    # @param [Symbol] level The log level to send to your Logger.
    def log(message, level = nil)
      level ||= self.class.default_log_level

      self.class.before_log.call
      yield if block_given?

      return unless self.class.logging_enabled?

      write_message(message, level)
    end

    private

    def write_message(message, level)
      if message.respond_to?(:each_line)
        message.each_line { |line| logger.send(level, filter_class_name(line.chomp)) }
      else
        logger.send(level, filter_class_name(message))
      end
    end

    def filter_class_name(message)
      if self.class.log_class_name?
        "<#{self.class.name}> #{message}"
      else
        message
      end
    end
  end
end
