require 'diplomat'
require 'singleton'

require 'fireap/model/node'

module Fireap::Manager
  class Node
    include Singleton
    attr :nodes

    def initialize
      @nodes ||= {}
      Diplomat::Node.get_all.each do |nod|
        dnode  = Fireap::Model::Node.new(nod['Node'], nod['Address'])
        @nodes[dnode.name] = dnode
      end
    end

    # @param app [Fireap::Model::Application]
    def collect_app_info(app, ctx: nil)
      Fireap::DataAccess::Kv.get_recurse("#{app.name}/nodes/").each do |data|
        unless %r|#{app.name}/nodes/([^/]+)/([^/\s]+)$|.match(data.key)
          ctx.die("Unkwon key pattern! key=#{data.key}, val=#{data.value}")
        end
        nodename = $1
        propkey  = $2
        ctx.log.debug 'Got kv. %s:%s => %s'%[nodename, propkey, data.value]

        node = @nodes[nodename] or ctx.die("Unknown Node! #{nodename}")
        app  = node.apps[app.name] ||= Fireap::Model::Application.new(app.name, node: node)
        app.set_kv_prop(propkey, data)
      end
      @nodes.each_pair do |name, node|
        unless node.has_app?(app.name)
          node.apps[app.name] ||= Fireap::Model::Application.new(app.name, node: node)
        end
      end
      ctx.log.debug @nodes.to_s
    end

    # @param app [Fireap::Model::Application]
    # @param version [String]
    # @return [Hash{String => Fireap::Model::Node}] the key [String] means Node's name
    def select_updated(app, version, ctx: nil)
      updated = {}
      @nodes.each_pair do |name, node|
        unless napp = node.apps[app.name]
          ctx.log.debug "Not found app:#{app.name} for node:#{name}"
          next
        end
        napph = napp.to_hash
        nversion  = napph[:version]
        semaphore = napph[:semaphore]
        ctx.log.debug "Node #{name} - Version = #{nversion}, Semaphore=#{semaphore}"
        if (nversion == version && semaphore.to_i > 0) or ctx.develop_mode?
          updated[name] = node
        end
      end
      updated
    end
  end
end
