require 'json'
require 'thor'

require 'diffusul/deploy'
require 'diffusul/watch'

module Diffusul
  class CLI < Thor
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
  end
end
