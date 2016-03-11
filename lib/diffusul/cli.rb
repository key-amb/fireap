require 'diplomat'
require 'json'
require 'thor'

require 'diffusul/config'
require 'diffusul/deploy'
require 'diffusul/watch'

module Diffusul
  class CLI < Thor
    @@config
    package_name "Diffusul::CLI"

    desc 'deploy', 'Deploy target app'
    option 'app', :required => true, :aliases => 'a'
    option 'version', :aliases => 'v'
    def deploy
      Diffusul::Deploy.start(options)
    end

    desc 'watch', 'Watch Deploy Event'
    def watch
      event = ''
      while ins = $stdin.gets
        event << ins
      end
      Diffusul::Watch.handle( JSON.parse(event) )
    end

    def self.start(argv)
      @@config ||= Diffusul::Config.new
      super(argv)
    end
  end
end
