require 'base64'

module Diffusul
  module Watch
    def self.handle(events: nil, config: nil)
      payload = nil
      evt = events.last
      evt.each_pair do |key, val|
        if key == 'Payload'
          payload = JSON.parse( Base64.decode64(val) )
          break
        end
      end
      app     = payload['app']
      new_ver = payload['version']
      unless config.deploy['apps'][app]
        raise "Not configured app! #{app}"
      end
      me   = Diffusul::Rest.get('/agent/self')
      node = me['Member']['Name']
      cur_ver = Diffusul::Kv.get("#{app}/nodes/#{node}/version", :return)
      if cur_ver == new_ver
        puts "Already updated. version=#{new_ver} Nothing to do."
        return
      end

      #nodes = Diplomat::Kv.get
    end
  end
end
