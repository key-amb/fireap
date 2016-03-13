require 'thor'

require 'diffusul/config'
require 'diffusul/context'
require 'diffusul/deployer'
require 'diffusul/watcher'

module Diffusul
  class CLI < Thor
    @ctx
    package_name "Diffusul::CLI"
    class_option 'config',  :aliases => 'c'
    class_option 'debug',   :aliases => 'd'

    desc 'deploy', 'Deploy target app'
    option 'app', :required => true, :aliases => 'a'
    option 'version', :aliases => 'v'
    def deploy
      load_context(options)
      Diffusul::Deployer.new(options, ctx: @ctx).start(options)
    end

    desc 'watch', 'Watch Deploy Event'
    option 'dry-run', :aliases => 'n'
    def watch
      load_context(options)
      Diffusul::Watcher.new(options, ctx: @ctx).wait_and_handle
    end

    desc 'clear', 'Clear deploy lock of target app'
    option 'app', :required => true, :aliases => 'a'
    def clear
      load_context(options)
      Diffusul::Deployer.new(options, ctx: @ctx).release_lock
      puts "Successfully cleared lock for app=#{options['app']}."
    end

    private

    def load_context(options)
      @ctx ||= proc {
        opt = {
          config_path:  options['config'],
          dry_run:      options['dry-run'],
          develop_mode: options['debug'],
        }
        Diffusul::Context.new(opt)
      }.call
      if ! @ctx.develop_mode? and options['debug']
        @ctx.log.warn %q[You specified DEBUG option. But DEBUG mode is disabled by configuration. Please set `enable_debugging = "ON"` in your config file.]
      end
    end
  end
end
