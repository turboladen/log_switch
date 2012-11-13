module LogSwitch
  module Mixin

    # When this module is included, this method gets called and defines a +#log+
    # method on the including class.
    #
    # @param [Class] klass The class that's including this module.
    # @raise [RuntimeError] If {LogSwitch.extender} isn't set (which gets set
    #    when you +extend+ your class with {LogSwitch}).
    def self.included(klass)
      if LogSwitch.extender
        klass.send :define_method, :log do |*args|
          if LogSwitch.extender.log_class_name? &&
            LogSwitch.extender.logger.class == Logger

            if args.size == 1
              args = "<#{klass}> #{args.join}"
            else
              msg = args.delete_at 0
              args.unshift("<#{klass}> #{msg}")
            end
          end

          LogSwitch.extender.log *args
        end
      else
        raise "No class has been extended by LogSwitch yet."
      end
    end
  end
end
