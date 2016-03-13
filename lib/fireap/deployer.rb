require 'socket'

require 'diffusul/application'
require 'diffusul/kv'

module Diffusul
  class Deployer
    @@default_semaphore = 2
    attr :ctx, :config, :app, :max_semaphore

    def initialize(options, ctx: nil)
      @app    = options['app']
      @ctx    = ctx
      @config = ctx.config.deploy
      @max_semaphore = @config['max_semaphores'] || @@default_semaphore
    end

    def start(options)
      payload = prepare(options)
      args = [ 'diffusul:deploy', payload.to_json ]
      Diplomat::Event.fire(*args)
      self.release_lock
      ctx.log.info "Deploy event fired. data = #{payload.to_s}"
    end

    def get_lock
      @lock_key ||= "#{@app}/lock"
      if Diffusul::Kv.get(@lock_key, :return).length > 0
        @ctx.die("#{@app} is already locked! Probably deploy is ongoing.")
      end
      unless Diffusul::Kv.put(@lock_key, Socket.gethostname)
        @ctx.die("Failed to put kv! key=#{@app}")
      end
    end

    def release_lock
      @lock_key ||= "#{@app}/lock"
      unless Diffusul::Kv.delete(@lock_key)
        @ctx.die("Failed to delete kv! key=#{@app}")
      end
    end

    private

    def prepare(options)
      config  = ctx.config.deploy
      unless config['apps'][@app]
        ctx.die("Not configured app! #{@app}")
      end

      self.get_lock
      app = Diffusul::Application.find_or_new(@app, @ctx.mynode)

      version = options['version'] || app.version.next_version
      app.semaphore.update(@max_semaphore)
      app.version.update(version)
      { app: @app, version: version }
    end
  end
end
