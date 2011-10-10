require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Kernel do
  def self.get_requires
    Dir[File.dirname(__FILE__) + '/../lib/log_switch/**/*.rb']
  end

  # Try to require each of the files in LogSwitch
  get_requires.each do |r|
    it "should require #{r}" do

      # A require returns true if it was required, false if it had already been
      # required, and nil if it couldn't require.
      Kernel.require(r.to_s).should_not be_nil
    end
  end
end

describe "LogSwitch" do
  around :each do |example|
    class MyClass; extend LogSwitch; end;
    example.run
    MyClass.reset_config!
  end

  it { LogSwitch::VERSION.should == '0.1.4' }

  describe "log" do
    it "should default to true" do
      MyClass.log?.should be_true
    end

    it "can log at any log level" do
      logger = double "Logger"
      logger.should_receive(:send).with(:meow, "stuff")
      MyClass.logger = logger
      MyClass.log("stuff", :meow)
    end

    it "raises when log_level isn't a Symbol" do
      expect { MyClass.log("stuff", "meow") }.to raise_error NoMethodError
    end
  end

  describe "log=" do
    it "allows to set logging to false" do
      MyClass.log = false
      MyClass.log?.should be_false
    end
  end

  describe "logger" do
    it "is a Logger by default" do
      MyClass.logger.should be_a Logger
    end
  end

  describe "logger=" do
    it "allows to set to use another logger" do
      original_logger = MyClass.logger
      another_logger = Logger.new nil
      MyClass.logger = another_logger
      MyClass.logger.should_not == original_logger
    end
  end

  describe "log_level" do
    it "defaults to :debug" do
      MyClass.log_level.should == :debug
    end
  end

  describe "log_level=" do
    it "changes the level that #log(msg, level=) uses" do
      MyClass.logger.should_receive(:debug)
      MyClass.log("testing...")
      MyClass.log_level = :info
      MyClass.logger.should_receive(:info)
      MyClass.log("testing...")
    end
  end
end
