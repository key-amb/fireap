require 'thor'

require 'diffusul/config'
require 'diffusul/context'
require 'diffusul/deploy'
require 'diffusul/watch'

module Diffusul
  class CLI < Thor
    @ctx
    package_name "Diffusul::CLI"
    class_option 'config', :aliases => 'c'
    class_option 'debug',  :aliases => 'd'

    desc 'deploy', 'Deploy target app'
    option 'app', :required => true, :aliases => 'a'
    option 'version', :aliases => 'v'
    def deploy
      load_context(options)
      Diffusul::Deploy.new(options, ctx: @ctx).start(options)
    end

    desc 'watch', 'Watch Deploy Event'
    def watch
      load_context(options)
      Diffusul::Watch.new(options, ctx: @ctx).wait_and_handle
    end

    desc 'clear', 'Clear deploy lock of target app'
    option 'app', :required => true, :aliases => 'a'
    def clear
      load_context(options)
      Diffusul::Deploy.new(options, ctx: @ctx).release_lock
      puts "Successfully cleared lock for app=#{options['app']}."
    end

    private

    def load_context(options)
      @ctx ||= proc {
        opt = {
          config_path:  options['config'],
          develop_mode: options['debug'],
        }
        Diffusul::Context.new(opt)
      }.call
    end
  end
end
