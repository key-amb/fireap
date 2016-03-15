require 'thor'

require 'fireap/config'
require 'fireap/context'
require 'fireap/controller/fire'
require 'fireap/monitor'
require 'fireap/watcher'

module Fireap
  class CLI < Thor
    @ctx
    package_name "Fireap::CLI"
    class_option 'config',  :aliases => 'c'
    class_option 'debug',   :aliases => 'd'

    desc 'fire', 'Fire deploy event for target Application'
    option 'app', :required => true, :aliases => 'a'
    option 'version', :aliases => 'v'
    def fire
      load_context(options)
      Fireap::Controller::Fire.new(options, ctx: @ctx).start(options)
    end

    desc 'reap', 'Watch and Reap a deploy event'
    option 'dry-run', :aliases => 'n'
    def reap
      load_context(options)
      Fireap::Watcher.new(options, ctx: @ctx).wait_and_handle
    end

    desc 'clear', 'Clear deploy lock of target app'
    option 'app', :required => true, :aliases => 'a'
    def clear
      load_context(options)
      Fireap::Controller::Fire.new(options, ctx: @ctx).release_lock
      puts "Successfully cleared lock for app=#{options['app']}."
    end

    desc 'monitor', 'Monitor deploy propagation of target app'
    option 'app', :required => true, :aliases => 'a'
    def monitor
      load_context(options)
      Fireap::Monitor.new(options, ctx: @ctx).monitor(options)
    end

    private

    def load_context(options)
      @ctx ||= proc {
        opt = {
          config_path:  options['config'],
          dry_run:      options['dry-run'],
          develop_mode: options['debug'],
        }
        Fireap::Context.new(opt)
      }.call
      if ! @ctx.develop_mode? and options['debug']
        @ctx.log.warn %q[You specified DEBUG option. But DEBUG mode is disabled by configuration. Please set `enable_debugging = "ON"` in your config file.]
      end
    end
  end
end
