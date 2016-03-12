require 'base64'
require 'timeout'

module Diffusul
  class Watch
    @@default_timeout  = 600 # seconds
    @@loop_interval    = 5
    @@restore_interval = 3
    @@restore_retry    = 3

    def self.handle(events: nil, ctx: nil)
      unless data = get_event_data(events, ctx: ctx)
        return
      end
      app = Diffusul::Application.new(data['app'], version: data['version'])

      if ctx.mynode.get_or_newapp(app.name).version == app.version
        ctx.log.info "App #{app.name} already updated. version=#{app.version} Nothing to do."
        return
      end

      watch_sec = ctx.config.deploy['watch_timeout'] || @@default_timeout
      Timeout.timeout(watch_sec) do |t|
        update_myapp(app, ctx: ctx)
      end
    end

    def self.get_event_data(events, ctx: nil)
      data = nil
      unless evt = events.last
        ctx.log.debug 'Event not happend yet.'
        return
      end

      evt.each_pair do |key, val|
        if key == 'Payload'
          data = JSON.parse( Base64.decode64(val) )
          ctx.log.debug data.to_s
          break
        end
      end

      unless ctx.config.deploy['apps'][data['app']]
        raise "Not configured app! #{data['app']}"
      end

      data
    end

    def self.update_myapp(app, ctx: nil)
      appname = app.name
      version = app.version

      updated = false
      while !updated
        nodes = Diffusul::NodeTable.new
        nodes.set_by_app(app, ctx: ctx)

        candidates = nodes.select_updated(app, ctx: ctx)
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

      # Update succeeded. So set node's version and semaphore
      Diffusul::AppNode.new({
        app:       app.name,
        node:      ctx.mynode.name,
        version:   app.version,
        semaphore: Diffusul::Deploy.get_max_semaphore(ctx: ctx),
      }).save(ctx)
      ctx.log.info "[#{ctx.mynode.name}] Updated app #{app.name} to version #{app.version} ."
    end

    def self.restore_semaphore(semaphore)
      (1..@@restore_retry).each do |i|
        semaphore.renew
        return true if semaphore.restore
        sleep @@restore_interval
      end
      false
    end
  end
end
