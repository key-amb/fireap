require 'socket'

require 'fireap'
require 'fireap/manager/node'
require 'fireap/manager/node_factory'
require 'fireap/model/application'
require 'fireap/model/event'
require 'fireap/data_access/kv'

module Fireap::Controller
  class Fire
    @@default_semaphore = 2
    @@wait_interval     = 2

    def initialize(options, ctx)
      @appname = options['app']
      @version = options['version'] || nil
      @ctx     = ctx
      @appconf = ctx.config.app_config(@appname)
    end

    def fire(options)
      payload = prepare_event(options)
      return unless payload

      params = {
        payload:        payload,
        service_filter: @appconf.service_filter,
        tag_filter:     @appconf.tag_filter,
      }
      Fireap::Model::Event.new(params).fire
      @ctx.log.info "Event Fired! Params = #{params.inspect}"

      if @appconf.wait_after_fire.to_i > 0
        unless wait_propagation
          @ctx.log.warn <<"EOS"
Task #{@appname} propagation is unfinished.
If you want to check the propagation, do following:

    % #{Fireap::NAME} monitor -a #{@appname}

Or check the logs.
EOS
        end
      end
      self.release_lock
    end

    def get_lock
      @lock_key ||= "#{@appname}/lock"
      if Fireap::DataAccess::Kv.get(@lock_key, :return).length > 0
        @ctx.log.warn(<<"EOS")
Task #{@appname} is already locked! Maybe update is ongoing. Please Check!
If you want to clear the lock, do following:

    % #{Fireap::NAME} clear -a #{@appname}

EOS
        return false
      end
      unless Fireap::DataAccess::Kv.put(@lock_key, Socket.gethostname)
        @ctx.die("Failed to put kv! key=#{@appname}")
      end
      @ctx.log.debug "Succeed to get lock for app=#{@appname}"
      return true
    end

    def release_lock
      @lock_key ||= "#{@appname}/lock"
      unless Fireap::DataAccess::Kv.delete(@lock_key)
        @ctx.die("Failed to delete kv! key=#{@appname}")
      end
    end

    private

    def prepare_event(options)
      unless @ctx.config.app_config(@appname)
        @ctx.die("Not configured app! #{@appname}")
      end

      return unless self.get_lock
      app = Fireap::Model::Application.find_or_new(@appname, @ctx.mynode)

      @version ||= app.version.next_version
      app.semaphore.update(@appconf.max_semaphores)
      app.version.update(@version)

      payload = { app: @appname, version: @version }
    end

    def wait_propagation
      wait_s = @appconf.wait_after_fire
      time_s = Time.now.to_i
      @app   = Fireap::Model::Application.new(@appname)
      nodes  = target_nodes()
      node_num = nodes.size
      interval = (@@wait_interval > wait_s) ? sec : @@wait_interval

      interrupt = 0
      Signal.trap(:INT) { interrupt = 1 }

      try = 1
      finished = false
      while interrupt == 0
        @ctx.log.info "Waiting for propagation ... trial: #{try}"
        sleep interval

        ntbl = Fireap::Manager::Node.instance
        ntbl.collect_app_info(@app, ctx: @ctx)
        updated = ntbl.select_updated(@app, @version, ctx: @ctx)
        updated_num = compare_nodes_and_updated(nodes, updated)
        @ctx.log.info '%d/%d nodes updated.' % [updated_num, node_num]

        if updated_num == node_num
          @ctx.log.info 'Complete!'
          finished = true
          break
        end
        break if (Time.now.to_i - time_s) >= wait_s
      end
      finished
    end

    def target_nodes
      if @appconf.service_filter
        Fireap::Manager::NodeFactory.catalog_service_by_filter(
          @appconf.service_filter, tag_filter: @appconf.tag_filter)
      else
        Fireap::Manager::Node.instance.nodes
      end
    end

    # @return [Fixnum] Updated node number
    def compare_nodes_and_updated(nodes, updated)
      if nodes.class == Hash and nodes.size >= updated.size
        updated.size
      else # nodes is from NodeFactory
        match = updated.select do |key, val|
          nodes.find_index do |nd|
            nd.address == val.address
          end
        end
        match.size
      end
    end
  end
end
