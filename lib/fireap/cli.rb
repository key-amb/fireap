require 'thor'

require 'fireap/config'
require 'fireap/context'
require 'fireap/controller/fire'
require 'fireap/controller/monitor'
require 'fireap/controller/reap'

module Fireap
  class CLI < Thor
    @ctx
    package_name "Fireap::CLI"
    class_option 'config',  :aliases => 'c'
    class_option 'debug',   :aliases => 'd'

    desc 'fire', 'Fire an update Event for target Application'
    option 'app', :required => true, :aliases => 'a'
    option 'version', :aliases => 'v'
    def fire
      load_context(options)
      Fireap::Controller::Fire.new(options, @ctx).fire(options)
    end

    desc 'reap', 'Watch and Reap a fired event'
    option 'dry-run', :aliases => 'n'
    def reap
      load_context(options)
      Fireap::Controller::Reap.new(options, @ctx).reap
    end

    desc 'clear', 'Clear Fire Lock for target Application'
    option 'app', :required => true, :aliases => 'a'
    def clear
      load_context(options)
      Fireap::Controller::Fire.new(options, @ctx).release_lock
      puts "Successfully cleared lock for app=#{options['app']}."
    end

    desc 'monitor', 'Monitor update propagation of target Application'
    option 'app', :required => true, :aliases => 'a'
    option 'interval', :aliases => 'i'
    option 'one-shot', :aliases => 'o'
    def monitor
      load_context(options)
      monitor = Fireap::Monitor.new(options, @ctx)
      return monitor.oneshot(options) if options['one-shot']
      monitor.monitor(options)
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
