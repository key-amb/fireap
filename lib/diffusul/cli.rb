require 'diplomat'
require 'json'
require 'thor'

require 'diffusul/application'
require 'diffusul/appnode'
require 'diffusul/config'
require 'diffusul/context'
require 'diffusul/deploy'
require 'diffusul/kv'
require 'diffusul/node'
require 'diffusul/nodetable'
require 'diffusul/rest'
require 'diffusul/semaphore'
require 'diffusul/string'
require 'diffusul/watch'

module Diffusul
  class CLI < Thor
    @ctx
    package_name "Diffusul::CLI"
    class_option 'config', :aliases => 'c'

    desc 'deploy', 'Deploy target app'
    option 'app', :required => true, :aliases => 'a'
    option 'version', :aliases => 'v'
    def deploy
      load_ctx(options['config'])
      Diffusul::Deploy.start(options, ctx: @ctx)
    end

    desc 'watch', 'Watch Deploy Event'
    def watch
      load_ctx(options['config'])
      events = ''
      while ins = $stdin.gets
        events << ins
      end
      Diffusul::Watch.handle(events: JSON.parse(events), ctx: @ctx)
    end

    desc 'clear', 'Clear deploy lock of target app'
    option 'app', :required => true, :aliases => 'a'
    def clear
      load_ctx(options['config'])
      Diffusul::Deploy.release_lock(options['app'])
      puts "Successfully cleared lock for app=#{options['app']}."
    end

    private

    def load_ctx(path)
      @ctx ||= proc {
        opt = {}
        opt['config_path'] = path if path
        Diffusul::Context.get(opt)
      }.call
    end
  end
end
