require 'base64'
require 'timeout'

require 'fireap/model/application'
require 'fireap/model/application_node'
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

    # @param ctx [Fireap::Context]
    def initialize(options, ctx)
      @ctx     = ctx
      @config  = ctx.config
      @event   = nil
      @appconf = nil
      @myapp   = nil
      @myappnode = nil
    end

    def reap
      unless evt = Fireap::Model::Event.fetch_from_stdin
        @ctx.log.info 'Event not happend yet. Do nothing.'
        return
      end
      @ctx.log.debug evt.to_s
      @event = evt.payload

      return unless prepare_reap()

      watch_sec = @appconf.watch_timeout || @@default_timeout
      result = nil
      Timeout.timeout(watch_sec) do |t|
        result = update_myapp()
      end

      if result
        @ctx.log.info "Update is successful. app=#{@myapp.name}, version=#{@event['version']}"
      else
        @ctx.log.error "Update failed! app=#{@myapp.name}, version=#{@event['version']}"
      end
    end

    private

    def prepare_reap
      unless @appconf = @config.app_config(@event['app'])
        @ctx.die("Not configured app! #{@event['app']}")
      end

      @myapp = Fireap::Model::Application.find_or_new(
        @event['app'], @ctx.mynode, ctx: @ctx
      )
      @myappnode = Fireap::Model::ApplicationNode.new(@myapp, @ctx.mynode, ctx: @ctx)

      if @myapp.version.value == @event['version']
        @ctx.log.info(
          "App #{@event['app']} already updated. version=#{@event['version']} Nothing to do.")
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

        candidates = @myappnode.find_updated_nodes(version)
        if candidates.empty?
          @ctx.log.warn "Can't fetch updated app from any node! app=#{appname}, version=#{version}"
          sleep @@loop_interval
          next
        end

        candidates.shuffle.each do |appnode|
          unless appnode.app.semaphore.consume(cas: true)
            @ctx.log.debug "Can't get semaphore from #{appnode.node.name}; app=#{appname}"
            next
          end

          begin
            pull_update(appnode.node)
            updated = true
            return updated
          ensure
            unless restore_semaphore(appnode.app.semaphore)
              @ctx.die("Failed to restore semaphore! app=#{appname}, node=#{host}")
            end
          end
        end

        sleep @@loop_interval
      end
      updated
    end

    def pull_update(node)
      appname = @myapp.name
      new_version = @event['version']

      @ctx.log.debug "Start pulling update #{appname} from #{node.name} toward #{new_version}."
      job = Fireap::Model::Job.new(ctx: @ctx)
      @results = job.run_commands(app: @myapp, remote: node)

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
      cnt = @myapp.update_properties(
        version: new_version,
        semaphore: @appconf.max_semaphores,
        remote_node: node.name,
      )
      unless cnt == 3
        @ctx.log.error "Update some properties Failed! updated count = #{cnt}. Should be 3."
      end
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
