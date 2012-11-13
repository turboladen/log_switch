require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'log_switch/mixin'


class Tester
end


describe LogSwitch::Mixin do
  describe ".included" do
    context "LogSwitch.extender is set" do
      let!(:logger_class) { double "LogSwitch.logger" }

      before do
        LogSwitch.stub(:extender).and_return logger_class
      end

      it "takes a class and defines the #log method on it" do
        Tester.should_receive(:send).with(:define_method, :log)

        class Tester
          include LogSwitch::Mixin
        end
      end

      it "results in an object with a #log message" do
        class Tester
          include LogSwitch::Mixin
        end

        Tester.new.methods.should include(:log)
      end

      context "LogSwitch.extender.log_class_name? is true" do
        before do
          LogSwitch.unstub(:extender)
        end

        context "just a log message passed to logger" do
          it "adds the class name to the log message" do
            class Tester
              extend LogSwitch
              include LogSwitch::Mixin
              def meow; log "hi"; end
            end

            Tester.log_class_name = true
            Tester.logger = Logger.new($stdout)
            Tester.should_receive(:log).with("<Tester> hi")
            t = Tester.new
            t.meow
          end
        end

        context "log message and level passed to logger" do
          it "adds the class name to the log message" do
            class Tester
              extend LogSwitch
              include LogSwitch::Mixin
              def meow; log "hi", :warn; end
            end

            Tester.log_class_name = true
            Tester.logger = Logger.new($stdout)
            Tester.should_receive(:log).with("<Tester> hi", :warn)
            t = Tester.new
            t.meow
          end
        end
      end
    end

    context "LogSwitch.extender is not set" do
      before { LogSwitch.stub(:extender).and_return nil }

      it "raises a RuntimeError" do
        expect {
          class Tester
            include LogSwitch::Mixin
          end
        }.to raise_error RuntimeError
      end
    end
  end
end
