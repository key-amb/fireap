require 'socket'

module Diffusul
  class Deploy
    @@default_semaphore = 2

    def self.start(options, ctx: nil)
      payload = prepare(options, ctx: ctx)
      args = [ 'diffusul:deploy', payload.to_json ]
      Diplomat::Event.fire(*args)
      release_lock(options['app'])
    end

    def self.prepare(options, ctx: nil)
      app    = options['app']
      config = ctx.config.deploy
      unless config['apps'][app]
        ctx.die("Not configured app! #{app}")
      end
      get_lock(app, ctx: ctx)
      me   = Diffusul::Rest.get('/agent/self')
      node = me['Member']['Name']
      version = options['version'] || get_next_version(app, node: node, ctx: ctx)
      kvs = {
        version:   version,
        semaphore: get_max_semaphore(ctx: ctx),
      }
      kvs.each_pair do |key, val|
        k = "#{app}/nodes/#{node}/#{key}"
        unless Diffusul::Kv.put(k, val.to_s)
          ctx.die("Failed to put kv! key=#{k}, val=#{val}")
        end
      end
      { app: app, version: version }
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

    def self.get_next_version(app, node: nil, ctx: nil)
      @current_version = Diffusul::Kv.get("#{app}/nodes/#{node}/version", :return)
      return 1 unless @current_version.length > 0
      version = nil
      if %r{(.*\D)?(\d+)(\D*)?}.match(@current_version.to_s)
        version = [$1, $2.to_i + 1, $3].join
      else
        version = @current_version + '-1'
      end
      ctx.log.debug("App=#{app} Current Ver=#{@current_version}, Next=#{version}")
      version
    end

    def self.get_max_semaphore(ctx: nil)
      ctx.config.deploy['max_semaphores'] || @@default_semaphore
    end
  end
end
