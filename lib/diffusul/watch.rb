require 'base64'
require 'timeout'

require 'diffusul/application'
require 'diffusul/deploy'
require 'diffusul/eventdata'
require 'diffusul/node'
require 'diffusul/nodetable'

module Diffusul
  class Watch
    @@default_timeout  = 600 # seconds
    @@loop_interval    = 5
    @@restore_interval = 3
    @@restore_retry    = 3

    attr :ctx, :event, :deploy, :myapp
    @event  = nil
    @deploy = nil
    @myapp  = nil

    def initialize(options, ctx: nil)
      @ctx = ctx
    end

    def wait_and_handle
      if @event = wait()
        @ctx.log.debug @event.to_s
        handle()
      end
    end

    private

    def wait
      streams = ''
      while ins = $stdin.gets
        streams << ins
      end

      ev_data = Diffusul::EventData.create_by_streams(streams)
      unless ev_data.length > 0
        @ctx.log.debug 'Event not happend yet.'
        return
      end
      ev_data.last.payload
    end

    def handle
      return unless prepare()

      watch_sec = ctx.config.deploy['watch_timeout'] || @@default_timeout
      Timeout.timeout(watch_sec) do |t|
        update_myapp()
      end
    end

    def prepare
      unless @ctx.config.deploy['apps'][@event['app']]
        @ctx.die("Not configured app! #{@event['app']}")
      end

      @deploy = Diffusul::Deploy.new({
        'app' => @event['app'],
      }, ctx: @ctx )

      @myapp = Diffusul::Application.find_or_new(@event['app'], @ctx.mynode)

      if @myapp.version.value == @event['version']
        @ctx.log.info "App #{@event['app']} already updated. version=#{@event['version']} Nothing to do."
        return
      end

      return true
    end

    def update_myapp
      appname = @myapp.name
      version = @event['version']

      updated = false
      while !updated
        nodes = Diffusul::NodeTable.new
        nodes.set_by_app(@myapp, ctx: ctx)

        candidates = nodes.select_updated(@myapp, version, ctx: ctx)
        if candidates.empty?
          ctx.die("Can't fetch updated app from any node! app=#{appname}, version=#{version}")
        end

        candidates.each_pair do |host, node|
          nodeapp = node.apps[appname]
          unless nodeapp.semaphore.consume
            ctx.log.debug "Can't get semaphore from #{host}; app=#{appname}"
            next
          end

          begin
            pull_update(node, ctx: ctx)
            updated = true
            break
          ensure
            unless restore_semaphore(nodeapp.semaphore)
              ctx.die("Failed to restore semaphore! app=#{appname}, node=#{host}")
            end
          end
        end

        sleep @@loop_interval
      end
    end

    def pull_update(node, ctx: nil)
      appname = @myapp.name
      ctx.log.debug "Will update #{appname} from #{node.name}."
      new_version = node.apps[appname].version

      # Update succeeded. So set node's version and semaphore
      @myapp.semaphore.update(deploy.max_semaphore)
      @myapp.version.update(new_version)
      ctx.log.info "[#{ctx.mynode.name}] Updated app #{appname} to version #{new_version} ."
    end

    def restore_semaphore(semaphore)
      (1..@@restore_retry).each do |i|
        semaphore = semaphore.refetch
        return true if semaphore.restore
        sleep @@restore_interval
      end
      false
    end
  end
end
