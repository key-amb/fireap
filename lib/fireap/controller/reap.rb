require 'base64'
require 'timeout'

require 'fireap/model/application'
require 'fireap/controller/fire'
require 'fireap/model/event'
require 'fireap/model/job'
require 'fireap/model/node'
require 'fireap/manager/node'

module Fireap::Controller
  class Reap
    @@default_timeout  = 600 # seconds
    @@loop_interval    = 5
    @@restore_interval = 3
    @@restore_retry    = 3

    attr :ctx, :event, :deploy, :myapp

    def initialize(options, ctx: nil)
      @ctx = ctx
    end

    def reap
      if @event = wait_event()
        @ctx.log.debug @event.to_s
        handle_event()
      end
    end

    private

    def wait_event
      streams = ''
      while ins = $stdin.gets
        streams << ins
      end

      ev_data = Fireap::Model::Event.create_by_streams(streams)
      unless ev_data.length > 0
        @ctx.log.debug 'Event not happend yet.'
        return
      end
      ev_data.last.payload
    end

    def handle_event
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

      @deploy = Fireap::Controller::Fire.new({
        'app' => @event['app'],
      }, ctx: @ctx )

      @myapp = Fireap::Model::Application.find_or_new(@event['app'], @ctx.mynode)

      if @myapp.version.value == @event['version']
        @ctx.log.info "App #{@event['app']} already updated. version=#{@event['version']} Nothing to do."
        return unless @ctx.develop_mode?
      end

      return true
    end

    def update_myapp
      appname = @myapp.name
      version = @event['version']
      mynode  = @ctx.mynode

      updated = false
      while !updated
        ntable = Fireap::Manager::Node.instance
        ntable.collect_app_info(@myapp, ctx: @ctx)

        candidates = ntable.select_updated(@myapp, version, ctx: @ctx)
        if candidates.empty?
          @ctx.die("Can't fetch updated app from any node! app=#{appname}, version=#{version}")
        end

        candidates.each_pair do |host, node|
          if mynode.name == host
            ctx.log.info "Candidate node is myself. #{host} Skip."
            next unless ctx.develop_mode?
          end

          nodeapp = node.apps[appname]
          unless nodeapp.semaphore.consume(cas: true)
            @ctx.log.debug "Can't get semaphore from #{host}; app=#{appname}"
            next
          end

          begin
            pull_update(node)
            updated = true
            break
          ensure
            unless restore_semaphore(nodeapp.semaphore)
              @ctx.die("Failed to restore semaphore! app=#{appname}, node=#{host}")
            end
          end
        end

        sleep @@loop_interval
      end
    end

    def pull_update(node)
      appname = @myapp.name
      new_version = @event['version']

      @ctx.log.debug "Start pulling update #{appname} from #{node.name} toward #{new_version}."
      executor = Fireap::Model::Job.new(ctx: @ctx)
      @results = executor.run_commands(app: @myapp, remote: node)

      failed  = @results.select { |r| r.is_failed?  }
      ignored = failed.select   { |r| r.is_ignored? }
      if failed.length > 0
        if failed.length > ignored.length
          @ctx.die "[#{appname}] Update FAILED! cnt=#{failed.length}, ignored=#{ignored.length}. ABORT!"
        else
          @ctx.log.warn \
            "[#{appname}] Some commands failed. cnt=#{failed.length}, ignored=#{ignored.length}. CONTINUE ..."
        end
      else
        @ctx.log.info "[#{appname}] All commands Succeeded."
      end

      # Update succeeded. So set node's version and semaphore
      @myapp.semaphore.update(deploy.max_semaphore)
      @myapp.version.update(new_version)
      @myapp.update_info.update({
        updated_at:  Time.now.to_s,
        remote_node: node.name,
      }.to_json)
      @ctx.log.info "[#{@ctx.mynode.name}] Updated app #{appname} to version #{new_version} ."
    end

    def restore_semaphore(semaphore)
      (1..@@restore_retry).each do |i|
        semaphore = semaphore.refetch
        @ctx.log.debug "Restore semaphore (#{i}). key=#{semaphore.key}, current=#{semaphore.value}"
        return true if semaphore.restore
        sleep @@restore_interval
      end
      false
    end
  end
end
