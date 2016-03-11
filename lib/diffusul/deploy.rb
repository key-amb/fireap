require 'socket'

module Diffusul
  class Deploy
    @@default_semaphore = 2

    def self.start(options, config: nil)
      prepare(options, config: config)
      args = [ 'diffusul:deploy', options.to_json ]
      Diplomat::Event.fire(*args)
      release_lock(options['app'])
    end

    def self.prepare(options, config: nil)
      app = options['app']
      get_lock(app)
      me   = Diffusul::Rest.get('/agent/self')
      node = me['Member']['Name']
      version = options['version'] || get_next_version(app, node: node)
      kvs = {
        version:   version,
        semaphore: config['max_semaphores'] || @@default_semaphore,
      }
      kvs.each_pair do |key, val|
        _key = "diffusul/#{app}/nodes/#{node}/#{key}"
        unless Diplomat::Kv.put(_key, val.to_s)
          raise "Failed to put kv! key=#{_key}, val=#{val}"
        end
      end
    end

    def self.get_lock(app)
      @lock_key ||= "diffusul/#{app}/lock"
      if Diplomat::Kv.get(@lock_key, nil, :return).length > 0
        raise "#{app} is already locked! Probably deploy is ongoing."
      end
      unless Diplomat::Kv.put(@lock_key, Socket.gethostname)
        raise "Failed to put kv! key=#{app}"
      end
    end

    def self.release_lock(app)
      @lock_key ||= "diffusul/#{app}/lock"
      unless Diplomat::Kv.delete(@lock_key)
        raise "Failed to delete kv! key=#{app}"
      end
    end

    def self.get_next_version(app, node: nil)
      @current_version = Diplomat::Kv.get("diffusul/#{app}/nodes/#{node}/version", nil, :return)
      return 1 unless @current_version.length > 0
      if %r{(.*\D)?(\d+)(\D*)?}.match(@current_version.to_s)
        return [$1, $2.to_i + 1, $3].join
      else
        return @current_version + '-1'
      end
    end
  end
end
