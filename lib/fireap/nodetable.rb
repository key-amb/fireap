require 'diplomat'
require 'singleton'

require 'diffusul/node'

module Diffusul
  class NodeTable
    include Singleton
    attr :nodes

    def initialize
      @nodes ||= {}
      Diplomat::Node.get_all.each do |nod|
        dnode  = Diffusul::Node.new(nod['Node'], nod['Address'])
        @nodes[dnode.name] = dnode
      end
    end

    def collect_app_info(app, ctx: nil)
      mynode = ctx.mynode if ctx
      Diffusul::Kv.get_recurse("#{app.name}/nodes/").each do |data|
        unless %r|#{app.name}/nodes/([^/]+)/([^/\s]+)$|.match(data.key)
          ctx.die("Unkwon key pattern! key=#{data.key}, val=#{data.value}")
        end
        nodename = $1
        propkey  = $2
        ctx.log.debug 'Got kv. %s:%s => %s'%[nodename, propkey, data.value]
        if mynode and mynode.name == nodename
          ctx.log.info "Event transmitter is myself. #{nodename} Skip."
          next unless ctx.develop_mode?
        end

        node = @nodes[nodename] or ctx.die("Unknown Node! #{nodename}")
        app  = node.apps[app.name] ||= Diffusul::Application.new(app.name, node: node)
        app.set_kv_prop(propkey, data)
      end
      ctx.log.debug @nodes.to_s
    end

    def select_updated(app, version, ctx: nil)
      @nodes.select do |name, node|
        napp = node.apps[app.name] or ctx.die("Can't find app #{app.name} from node #{name}!")
        version   = napp.version.value
        semaphore = napp.semaphore.value
        ctx.log.debug "Node #{name} - Version = #{version}, Semaphore=#{semaphore}"
        (napp.version == version && semaphore > 0) \
          or ctx.develop_mode?
      end
    end
  end
end
