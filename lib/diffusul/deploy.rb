require 'socket'

require 'diffusul/application'

module Diffusul
  class Deploy
    @@default_semaphore = 2

    def self.start(options, ctx: nil)
      payload = prepare(options, ctx: ctx)
      args = [ 'diffusul:deploy', payload.to_json ]
      Diplomat::Event.fire(*args)
      release_lock(options['app'])
      ctx.log.info "Deploy event fired. data = #{payload.to_s}"
    end

    def self.prepare(options, ctx: nil)
      appname = options['app']
      config  = ctx.config.deploy
      unless config['apps'][appname]
        ctx.die("Not configured app! #{appname}")
      end

      get_lock(appname, ctx: ctx)
      app = Diffusul::Application.find_or_new(appname, ctx.mynode)

      version = options['version'] || app.version.next_version
      app.semaphore.update( get_max_semaphore(ctx: ctx) )
      app.version.update(version)
      { app: appname, version: version }
    end

    def self.get_lock(app, ctx: nil)
      @lock_key ||= "#{app}/lock"
      if Diffusul::Kv.get(@lock_key, :return).length > 0
        ctx.die("#{app} is already locked! Probably deploy is ongoing.")
      end
      unless Diffusul::Kv.put(@lock_key, Socket.gethostname)
        ctx.die("Failed to put kv! key=#{app}")
      end
    end

    def self.release_lock(app, ctx: nil)
      @lock_key ||= "#{app}/lock"
      unless Diffusul::Kv.delete(@lock_key)
        ctx.die("Failed to delete kv! key=#{app}")
      end
    end

    def self.get_max_semaphore(ctx: nil)
      ctx.config.deploy['max_semaphores'] || @@default_semaphore
    end
  end
end
