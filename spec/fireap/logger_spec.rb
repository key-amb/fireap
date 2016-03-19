require 'fireap/logger'

require 'logger'

class LoggerTester
  attr :logger, :outs
  def initialize(level, header)
    # Create output devices for test
    @outs   = (0..1).map do StringIO.new end
    @logger = Fireap::Logger.new(@outs, level: level, header: header)
  end
end

describe 'Fireap::Logger' do
  context 'when multi outputs are given with header and WARN level' do
    header = ':: head ::'
    message = 'test log message'

    describe "#log with [WARN] level logger. Message='#{message}'" do
      level  = 'WARN'

      context %q{given level [ERROR], log appears} do
        tester = LoggerTester.new(level, header)
        tester.logger.log(Logger::ERROR, message)

        tester.outs.each_with_index do |out, idx|
          expected = /\[ERROR\] #{header} #{message}/
          it "out[#{idx}] matches #{expected}" do
            expect(out.string).to match expected
          end
        end
      end

      context %q{given level [INFO], log wan't appear} do
        tester = LoggerTester.new(level, header)
        tester.logger.log(Logger::INFO, message)

        tester.outs.each_with_index do |out, idx|
          it "out[#{idx}] has no output" do
            expect(out.string).to eq ''
          end
        end
      end
    end

    describe "#debug Message='#{message}'" do
      context "when logger level=INFO" do
        tester = LoggerTester.new('INFO', header)
        tester.logger.debug(message)

        tester.outs.each_with_index do |out, idx|
          it "out[#{idx}] has no output" do
            expect(out.string).to eq ''
          end
        end
      end

      context "when logger level=DEBUG" do
        tester = LoggerTester.new('DEBUG', header)
        tester.logger.debug(message)

        tester.outs.each_with_index do |out, idx|
          expected = /\[DEBUG\] #{header} #{message}/
          it "out[#{idx}] matches #{expected}" do
            expect(out.string).to match expected
          end
        end
      end
    end
  end
end

