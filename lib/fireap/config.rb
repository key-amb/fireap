require 'diplomat'
require 'toml'

module Fireap
  class Config
    @@app_props = %w[
      max_semaphores on_command_failure before_commands exec_commands after_commands
    ]
    @me   = nil
    @appc = nil

    def initialize(path: ENV['FIREAP_CONFIG_PATH'] || 'config/fireap.toml')
      @me   = TOML.load_file(path)
      @appc = {}
      configure_diplomat()
    end

    def method_missing(method)
      unless @me.has_key?(method.to_s)
        #raise "No such method: #{method}!"
        nil
      else
        @me[method.to_s]
      end
    end

    def app_config(appname)
      require 'pp'
      @appc[app] ||= proc {
        base = self.task.select { |k,v| @@app_props.include?(k) }
        appc = self.task['apps'][appname]
        conf = base.merge(appc)
        conf['commands'] = []
        %w(before exec after).each do |phase|
          if cmds = conf.delete("#{phase}_commands")
            conf['commands'].concat(cmds)
          end
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

    class App
      attr :max_semaphores, :on_command_failure, :commands

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
