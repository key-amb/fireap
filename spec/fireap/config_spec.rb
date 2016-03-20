require 'fireap/config'

require 'lib/test_config'

require 'tempfile'
require 'toml'

class Fireap::Config
  def test_me
    @me
  end
end

describe 'Fireap::Config#validate' do
  context 'with wrong key' do
    tester = TestConfig.new(<<"EOS")
uri = "http://localhost:8500"
enable_debug = "true"
#{TestConfig.minimum_body}
max_semaphore = 5
EOS
    it 'raise Fireap::Config::Error' do
      expect { tester.config.validate }.to raise_error(
        Fireap::Config::Error,
        /\["uri", "enable_debug", "task.max_semaphore"\] extra/
      )
    end
  end
  context 'type miss match' do
    ['url = 5', "[log]\nlevel = {}"].each do |text|
      context "given #{text}" do
        tester = TestConfig.new(<<"EOS")
#{text}
#{TestConfig.minimum_body}
EOS
        it 'raise Fireap::Config::Error' do
          expect { tester.config.validate }.to \
            raise_error(Fireap::Config::Error, /type mismatch/)
        end
      end
    end
  end
end

describe 'Fireap::Config features' do
  context 'with minimum config' do
    tester = TestConfig.minimum
    it 'is valid config' do
      expect(tester.config.validate).to be true
    end
  end

  context 'with global configured params' do
    tester = TestConfig.basic

    it 'match with TOML' do
      expect(tester.config.test_me).to match tester.parsed
    end

    it 'is valid config' do
      expect(tester.config.validate).to be true
    end

    describe 'Top level keys are readable accessors' do
      tester.parsed.each_pair do |key, value|
        it "{key: '#{key}', value: '#{value.to_s}'}" do
          expect( tester.config.send(key) ).to match value
        end
      end
    end

    describe 'When undefined key specified, Returns nil' do
      it "no such a key" do
        expect( tester.config.no_such_a_key ).to be_nil
      end
    end
  end

  context 'with some app task settings' do
    tester = TestConfig.tasks

    it 'is valid config' do
      expect(tester.config.validate).to be true
    end

    describe 'Not configured App' do
      it 'return nil' do
        expect( tester.config.app_config('baz') ).to be nil
      end
    end

    describe 'App = "foo"' do
      parsed = tester.parsed['task']
      appc   = tester.config.app_config('foo')

      %w[ max_semaphores on_command_failure ].each do |key|
        it "#{key} is overridden" do
          expect( appc.send(key) ).to eq parsed['apps']['foo'][key]
        end
      end

      it %q[ failure is ignored ] do
        expect(appc.is_failure_ignored?).to be_truthy
      end

      commands = []
      [ parsed['before_commands'],
        parsed['apps']['foo']['exec_commands'],
        parsed['apps']['foo']['after_commands']
      ].each do |a|
        commands.concat(a)
      end

      it 'commands are partially overridden' do
        expect(appc.commands).to match_array(commands)
      end

      it 'service_regexp is ignored because service is specified' do
        expect(appc.service_filter).to eq '^foo$'
      end
      it 'tag_regexp is ignored because tag is specified' do
        expect(appc.tag_filter).to eq '^v1$'
      end
    end

    describe 'App = "bar"' do
      parsed = tester.parsed['task']
      appc   = tester.config.app_config('bar')

      %w[ max_semaphores wait_after_fire watch_timeout on_command_failure ].each do |key|
        it "#{key} - common setting is chosen" do
          expect( appc.send(key) ).to eq parsed[key]
        end
      end

      it %q[ failure isn't ignored ] do
        expect(appc.is_failure_ignored?).to be_falsy
      end

      commands = []
      [ parsed['before_commands'],
        parsed['exec_commands'],
        parsed['after_commands']
      ].each do |a|
        commands.concat(a)
      end

      it 'commands all come from common setting' do
        expect(appc.commands).to match_array(commands)
      end

      it 'service_regexp is taken as filter because service is omitted' do
        expect(appc.service_filter).to eq '^[bB]ar$'
      end
      it 'tag_regexp is taken as filter because tag is omitted' do
        expect(appc.tag_filter).to eq '^(master|slave)$'
      end
    end
  end
end

