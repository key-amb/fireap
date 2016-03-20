require 'diplomat'
require 'toml'

require 'fireap/validator'

module Fireap
  class Config
    Error = Class.new(StandardError)

    @@app_props = %w[
      max_semaphores wait_after_fire watch_timeout on_command_failure
      before_commands exec_commands after_commands
    ]
    @me   = nil
    @appc = nil

    def initialize(path: ENV['FIREAP_CONFIG_PATH'] || 'config/fireap.toml')
      @me   = TOML.load_file(path)
      @appc = {}
      configure_diplomat()
    end

    def method_missing(method)
      if @me.has_key?(method.to_s)
        @me[method.to_s]
      end
    end

    def validate
      rule = Fireap::Validator.new(
        'url'              => { isa: String, optional: 1 },
        'enable_debugging' => { isa: String, optional: 1 },
        'log' => {
          isa: Hash,
          optional: 1,
          rule: {
            'level'  => { isa: String, optional: 1 },
            'rotate' => { isa: String, optional: 1 },
            'file'   => { isa: String, optional: 1 },
          },
        },
        'task' => {
          isa: Hash,
          rule: {
            'max_semaphores'     => { isa: Fixnum, optional: 1 },
            'wait_after_fire'    => { isa: Fixnum, optional: 1 },
            'watch_timeout'      => { isa: Fixnum, optional: 1 },
            'on_command_failure' => { isa: String, optional: 1 },
            'before_commands'    => { isa: Array,  optional: 1 },
            'exec_commands'      => { isa: Array,  optional: 1 },
            'after_commands'     => { isa: Array,  optional: 1 },
            'apps'               => { isa: Hash },
          },
        },
      )
      begin
        result = rule.validate(@me)
      rescue => e
        message = <<"EOS"
Config validation FAILED!! Please check your configuration.
Errors:
  #{e}
EOS
        raise Error, message
      end
      true
    end

    def app_config(appname)
      @appc[appname] ||= proc {
        unless appc = self.task['apps'][appname]
          return nil # Not configured
        end
        base = self.task.select { |k,v| @@app_props.include?(k) }
        conf = base.merge(appc)
        conf['commands'] = []
        %w(before exec after).each do |phase|
          if cmds = conf.delete("#{phase}_commands")
            conf['commands'].concat(cmds)
          end
        end
        %w[service tag].each do |key|
          conf["#{key}_filter"] \
            = make_regexp_filter(conf.delete(key), conf.delete("#{key}_regexp"))
        end
        App.new(conf)
      }.call
    end

    private

    def configure_diplomat
      Diplomat.configure do |config|
        config.url = self.url if self.url
      end
    end

    def make_regexp_filter(name, regexp)
      name ? "^#{name}$" : regexp
    end

    class App
      attr :max_semaphores, :wait_after_fire, :watch_timeout
      attr :on_command_failure, :commands, :service_filter, :tag_filter

      def initialize(stash)
        stash.each_pair do |k,v|
          instance_variable_set("@#{k}", v)
        end
      end

      def is_failure_ignored?
        /^ignore$/i.match(@on_command_failure)
      end
    end
  end
end
