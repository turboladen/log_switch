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
          LogSwitch.extender.log *args
        end
      else
        raise "No class has been extended by LogSwitch yet."
      end
    end
  end
end
