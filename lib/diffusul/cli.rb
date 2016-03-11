require 'diplomat'
require 'json'
require 'thor'

require 'diffusul/config'
require 'diffusul/deploy'
require 'diffusul/kv'
require 'diffusul/rest'
require 'diffusul/watch'

module Diffusul
  class CLI < Thor
    @@config
    package_name "Diffusul::CLI"

    desc 'deploy', 'Deploy target app'
    option 'app', :required => true, :aliases => 'a'
    option 'version', :aliases => 'v'
    def deploy
      Diffusul::Deploy.start(options, config: @@config.deploy)
    end

    desc 'watch', 'Watch Deploy Event'
    def watch
      events = ''
      while ins = $stdin.gets
        events << ins
      end
      Diffusul::Watch.handle(events: JSON.parse(events), config: @@config)
    end

    desc 'clear', 'Clear deploy lock of target app'
    option 'app', :required => true, :aliases => 'a'
    def clear
      Diffusul::Deploy.release_lock(options['app'])
      puts "Successfully cleared lock for app=#{options['app']}."
    end

    def self.start(argv)
      @@config ||= Diffusul::Config.new
      super(argv)
    end
  end
end
