require 'socket'

require 'fireap/model/application'
require 'fireap/data_access/kv'

module Fireap::Controller
  class Fire
    @@default_semaphore = 2
    attr :ctx, :config, :app, :max_semaphore

    def initialize(options, ctx: nil)
      @app    = options['app']
      @ctx    = ctx
      @config = ctx.config.task
      @max_semaphore = @config['max_semaphores'] || @@default_semaphore
    end

    def fire(options)
      payload = prepare(options)
      args = [ Fireap::EVENT_NAME, payload.to_json ]
      Diplomat::Event.fire(*args)
      self.release_lock
      ctx.log.info "Event Fired! Data = #{payload.to_s}"
    end

    def get_lock
      @lock_key ||= "#{@app}/lock"
      if Fireap::DataAccess::Kv.get(@lock_key, :return).length > 0
        @ctx.die("Task #{@app} is already locked! Maybe update is ongoing. Please Check!")
      end
      unless Fireap::DataAccess::Kv.put(@lock_key, Socket.gethostname)
        @ctx.die("Failed to put kv! key=#{@app}")
      end
    end

    def release_lock
      @lock_key ||= "#{@app}/lock"
      unless Fireap::DataAccess::Kv.delete(@lock_key)
        @ctx.die("Failed to delete kv! key=#{@app}")
      end
    end

    private

    def prepare(options)
      config  = ctx.config.task
      unless config['apps'][@app]
        ctx.die("Not configured app! #{@app}")
      end

      self.get_lock
      app = Fireap::Model::Application.find_or_new(@app, @ctx.mynode)

      version = options['version'] || app.version.next_version
      app.semaphore.update(@max_semaphore)
      app.version.update(version)
      { app: @app, version: version }
    end
  end
end
