require 'base64'
require 'timeout'

require 'diffusul/application'
require 'diffusul/eventdata'
require 'diffusul/node'
require 'diffusul/nodetable'

module Diffusul
  class Watch
    @@default_timeout  = 600 # seconds
    @@loop_interval    = 5
    @@restore_interval = 3
    @@restore_retry    = 3

    def self.handle(events: nil, ctx: nil)
      ev_data = Diffusul::EventData.create_by_streams(events)
      unless data = ev_data.last.payload
        ctx.log.debug 'Event not happend yet.'
        return
      end
      ctx.log.debug data.to_s

      unless ctx.config.deploy['apps'][data['app']]
        raise "Not configured app! #{data['app']}"
      end

      app = Diffusul::Application.find_or_new(data['app'], ctx.mynode)

      if app.version == data['version']
        ctx.log.info "App #{app.name} already updated. version=#{app['version']} Nothing to do."
        return
      end

      watch_sec = ctx.config.deploy['watch_timeout'] || @@default_timeout
      Timeout.timeout(watch_sec) do |t|
        update_myapp(app, data['version'], ctx: ctx)
      end
    end

    def self.update_myapp(app, version, ctx: nil)
      appname = app.name

      updated = false
      while !updated
        nodes = Diffusul::NodeTable.new
        nodes.set_by_app(app, ctx: ctx)

        candidates = nodes.select_updated(app, version, ctx: ctx)
        if candidates.empty?
          ctx.die("Can't fetch updated app from any node! app=#{appname}, version=#{version}")
        end

        candidates.each_pair do |host, node|
          nodeapp = node.apps[app.name]
          unless nodeapp.semaphore.consume
            ctx.log.debug "Can't get semaphore from #{host}; app=#{app.name}"
            next
          end

          begin
            sync_app_from_node(node, app, ctx: ctx)
            updated = true
            break
          ensure
            unless restore_semaphore(nodeapp.semaphore)
              ctx.die("Failed to restore semaphore! app=#{app}, node=#{host}")
            end
          end
        end

        sleep @@loop_interval
      end

    end

    def self.sync_app_from_node(node, app, ctx: nil)
      ctx.log.debug "Will update #{app.name} from #{node.name}."
      new_version = node.apps[app.name].version

      # Update succeeded. So set node's version and semaphore
      app.semaphore.update( Diffusul::Deploy.get_max_semaphore(ctx: ctx) )
      app.version.update(new_version)
      ctx.log.info "[#{ctx.mynode.name}] Updated app #{app.name} to version #{new_version} ."
    end

    def self.restore_semaphore(semaphore)
      (1..@@restore_retry).each do |i|
        semaphore = semaphore.refetch
        return true if semaphore.restore
        sleep @@restore_interval
      end
      false
    end
  end
end
