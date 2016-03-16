require 'diplomat'
require 'socket'

require 'fireap'
require 'fireap/model/application'
require 'fireap/data_access/kv'

module Fireap::Controller
  class Fire
    @@default_semaphore = 2

    def initialize(options, ctx)
      @appname = options['app']
      @ctx     = ctx
      @appconf = ctx.config.app_config(@appname)
    end

    def fire(options)
      payload = prepare_event(options)
      return unless payload

      args = [ Fireap::EVENT_NAME, payload.to_json ]
      Diplomat::Event.fire(*args)
      self.release_lock
      @ctx.log.info "Event Fired! Data = #{payload.to_s}"
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
      config  = @ctx.config.task
      unless config['apps'][@appname]
        @ctx.die("Not configured app! #{@appname}")
      end

      return unless self.get_lock
      app = Fireap::Model::Application.find_or_new(@appname, @ctx.mynode)

      version = options['version'] || app.version.next_version
      app.semaphore.update(@appconf.max_semaphores)
      app.version.update(version)
      { app: @appname, version: version }
    end
  end
end
