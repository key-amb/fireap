require 'diffusul/config'

require 'tempfile'
require 'toml'

class Diffusul::Config
  def test_me
    @me
  end
end

class TestDiffusulConfig
  attr :parsed, :config
  def initialize(toml)
    @parsed = TOML.parse(toml)
    tmp = Tempfile.open('tmp') do |fp|
      fp.puts toml
      fp
    end

    ENV['DIFFUSUL_CONFIG_PATH'] = tmp.path
    @config = Diffusul::Config.new
  end
end

describe 'Diffusul::Config' do
  describe 'Basic feature' do
    tester = TestDiffusulConfig.new(<<"EOS")
url = "http://localhost:8500"
enable_debugging = ""

[log]
level = "INFO"
file  = "tmp/diffusul.log"
EOS

    it 'match with TOML' do
      expect(tester.config.test_me).to match tester.parsed
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

  describe 'App Deploy Settings' do
    tester = TestDiffusulConfig.new(<<"EOS")
## Common Deploy Settings
[deploy]
max_semaphores     = 5
on_command_failure = "abort"
before_commands = [ "common before" ]
exec_commands   = [ "common exec" ]
after_commands  = [ "common after" ]

[deploy.apps.foo]
max_semaphores     = 3
on_command_failure = "ignore"
exec_commands   = [ "foo exec1", "foo exec2" ]
after_commands  = [ "foo after" ]

[deploy.apps.bar]
EOS

    describe 'App = "foo"' do
      parsed = tester.parsed['deploy']
      appc   = tester.config.app_config('foo')

      %w[ max_semaphores on_command_failure ].each do |key|
        it key do
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
    end

    describe 'App = "bar"' do
      parsed = tester.parsed['deploy']
      appc   = tester.config.app_config('bar')

      %w[ max_semaphores on_command_failure ].each do |key|
        it key do
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
    end

  end

end

