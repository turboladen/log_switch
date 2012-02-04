require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'log_switch/mixin'


class Tester
end


describe LogSwitch::Mixin do
  describe "::included" do
    context "LogSwitch.extender is set" do
      let(:logger_class) do
        double "LogSwitch.logger"
      end

      before { LogSwitch.stub(:extender).and_return logger_class }

      it "takes a class and defines the #log method on it" do
        Tester.should_receive(:send).with(:define_method, :log)

        class Tester
          include LogSwitch::Mixin
        end

        LogSwitch.unstub(:extender)
      end

      it "results in an object with a #log message" do
        class Tester
          include LogSwitch::Mixin
        end

        Tester.new.methods.should include(:log)
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
