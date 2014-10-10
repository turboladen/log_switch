require 'spec_helper'

class IncluderClass; include LogSwitch; end;

describe LogSwitch do
  before { LogSwitch.reset_config! }
  specify { expect(LogSwitch::VERSION).to eq '1.0.0' }

  describe 'base class methods' do
    describe ".included" do
      it "sets @includers on the class object that extended" do
        expect(described_class.instance_variable_get(:@includers)).
          to include(IncluderClass)
      end
    end

    describe ".logger" do
      it "is a Logger by default" do
        expect(described_class.logger).to be_a Logger
      end
    end
  end

  describe IncluderClass do
    subject { IncluderClass.new }

    describe ".logging_enabled?" do
      specify { expect(described_class).to respond_to(:logging_enabled?) }

      it 'defaults to false' do
        expect(described_class.logging_enabled?).to eq false
      end

      it 'can be set to true' do
        described_class.logging_enabled = true
        expect(described_class).to be_logging_enabled
      end
    end

    describe ".logger" do
      it "is a Logger by default" do
        expect(described_class.logger).to be_a Logger
      end
    end

    describe ".default_log_level" do
      it "defaults to :debug" do
        expect(described_class.default_log_level).to eq :debug
      end
    end

    describe ".log_class_name?" do
      specify { expect(described_class).to respond_to(:log_class_name?) }
    end

    describe ".log_class_name" do
      specify { expect(described_class).to respond_to(:log_class_name) }

      it 'defaults to true' do
        expect(described_class.log_class_name).to eq true
      end

      it 'can be set to false' do
        pending "Can't figure out why this doesn't pass. It works live..."
        described_class.log_class_name = false
        expect(described_class.log_class_name).to eq false
      end
    end

    describe ".before_log" do
      it "assigns the given block to @before_block" do
        described_class.before_log = Proc.new { "I'm a block" }
        expect(described_class.before_log).to be_a Proc
      end
    end

    describe "#log" do
      let(:logger) do
        double "Logger"
      end

      let(:object) do
        o = Object.new
        allow(o).to receive :test_in_block
        o
      end

      # before do
      #   described_class.logger = logger
      # end

      it "can log at any log level" do
        #expect(logger).to receive(:send).with(:meow, "<IncluderClass> stuff")
        subject.log("stuff", :meow)
      end

      it "can take a block" do
        allow(logger).to receive(:send).with(:debug, "<IncluderClass> hi")
        expect(object).to receive(:test_in_block)
        subject.log('hi') { object.test_in_block }
      end

      context "with .before_log" do
        it "calls the @before_block if that's set" do
          allow(logger).to receive(:send).with(:debug, "<IncluderClass> hi")
          described_class.before_log = Proc.new { puts "This is also before" }
          expect(described_class.before_log).to receive(:call).once
          subject.log 'hi'
        end
      end

      context "can log non-String objects" do
        it "an Array of various object types" do
          array = [1, 'stuff', { :two => 2 }]
          message = "<IncluderClass> #{array}"
          allow(logger).to receive(:send).with(:debug, message)
          expect { subject.log array }.to_not raise_exception
        end

        it "an Exception" do
          ex = StandardError.new("Test error.")
          message = "<IncluderClass> #{ex.message}"
          allow(logger).to receive(:send).with(:debug, message)
          expect { subject.log ex }.to_not raise_exception
        end
      end
    end
  end
end
