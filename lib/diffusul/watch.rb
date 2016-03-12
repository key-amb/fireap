require 'base64'

module Diffusul
  module Watch
    def self.handle(events: nil, ctx: nil)
      payload = nil
      unless evt = events.last
        ctx.log.debug 'Event not happend yet.'
        return
      end
      evt.each_pair do |key, val|
        if key == 'Payload'
          payload = JSON.parse( Base64.decode64(val) )
          break
        end
      end
      app     = payload['app']
      new_ver = payload['version']
      unless ctx.config.deploy['apps'][app]
        raise "Not configured app! #{app}"
      end
      me   = Diffusul::Rest.get('/agent/self')
      node = me['Member']['Name']
      cur_ver = Diffusul::Kv.get("#{app}/nodes/#{node}/version", :return)
      if cur_ver == new_ver
        ctx.log.info "App #{app} already updated. version=#{new_ver} Nothing to do."
        return
      end

      nodes = Diffusul::Kv.get_recurse("#{app}/nodes/").select do |n|
        %r|#{app}/nodes/[^/]+/version$|.match(n['key']) && n['value'] == new_ver
      end
      if nodes.empty?
        ctx.die("Can't fetch updated app from any node! app=#{app}, version=#{new_ver}")
      end

      # nodes.sample
    end
  end
end
