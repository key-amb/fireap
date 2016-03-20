require 'tempfile'
require 'toml'

require 'fireap/config'

class TestConfig
  attr :parsed, :config

  def initialize(toml)
    @parsed = TOML.parse(toml)
    tmp = Tempfile.open('tmp') do |fp|
      fp.puts toml
      fp
    end

    ENV['FIREAP_CONFIG_PATH'] = tmp.path
    @config = Fireap::Config.new
  end

  def self.basic
    new(<<"EOS")
url = "http://localhost:8500"
enable_debugging = ""

[log]
level = "INFO"
file  = "tmp/fireap.log"
EOS
  end

  def self.tasks
    new(<<"EOS")
## Common Task Settings
[task]
max_semaphores     = 5
wait_after_fire    = 10
watch_timeout      = 120
on_command_failure = "abort"
before_commands = [ "common before" ]
exec_commands   = [ "common exec" ]
after_commands  = [ "common after" ]

[task.apps.foo]
max_semaphores     = 3
on_command_failure = "ignore"
exec_commands   = [ "foo exec1", "foo exec2" ]
after_commands  = [ "foo after" ]
service = "foo"
service_regexp = "^fooo*$"
tag = "v1"
tag_regexp = "^v.$"

[task.apps.bar]
service_regexp = "^[bB]ar$"
tag_regexp = "^(master|slave)$"
EOS
  end
end
