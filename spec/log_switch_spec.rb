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

  it { LogSwitch::VERSION.should == '0.3.0' }

  describe ".log" do
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

    it "can take a block" do
      object = Object.new
      object.stub :test_in_block
      object.should_receive(:test_in_block)

      MyClass.log('hi') { object.test_in_block }

      object.unstub :test_in_block
    end

    context "with .before" do
      it "calls the @before_block if that's set" do
        MyClass.before { puts "This is also before" }
        MyClass.instance_variable_get(:@before_block).should_receive(:call).once
        MyClass.log 'hi'
      end
    end

    context "can log non-String objects" do
      it "an Array of various object types" do
        array = [1, 'stuff', { :two => 2 }]
        MyClass.logger.should_receive(:send).with(:debug, array)
        expect { MyClass.log array }.to_not raise_exception
      end

      it "an Exception" do
        ex = StandardError.new("Test error.")
        MyClass.logger.should_receive(:send).with(:debug, ex)
        expect { MyClass.log ex }.to_not raise_exception
      end
    end
  end

  describe ".log=" do
    it "allows to set logging to false" do
      MyClass.log = false
      MyClass.log?.should be_false
    end
  end

  describe ".logger" do
    it "is a Logger by default" do
      MyClass.logger.should be_a Logger
    end
  end

  describe ".logger=" do
    it "allows to set to use another logger" do
      original_logger = MyClass.logger
      another_logger = Logger.new nil
      MyClass.logger = another_logger
      MyClass.logger.should_not == original_logger
    end
  end

  describe ".log_level" do
    it "defaults to :debug" do
      MyClass.log_level.should == :debug
    end
  end

  describe ".log_level=" do
    it "changes the level that #log(msg, level=) uses" do
      MyClass.logger.should_receive(:debug)
      MyClass.log("testing...")
      MyClass.log_level = :info
      MyClass.logger.should_receive(:info)
      MyClass.log("testing...")
    end
  end

  describe ".before" do
    it "assigns the given block to @before_block" do
      MyClass.before { "I'm a block" }
      MyClass.instance_variable_get(:@before_block).should be_a Proc
    end
  end
end
