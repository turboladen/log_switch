module LogSwitch
  module Mixin
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
