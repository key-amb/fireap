require 'diplomat'

module Diffusul
  module Deploy
    def self.start(options)
      args = [ 'diffusul:deploy', options.to_json ]
      Diplomat::Event.fire(args)
    end
  end
end
