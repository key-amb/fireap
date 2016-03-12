require 'base64'
require 'timeout'

module Diffusul
  class Watch
    @@default_timeout  = 600 # seconds
    @@loop_interval    = 5
    @@restore_interval = 3
    @@restore_retry    = 3

    @@node_name = nil

    def self.handle(events: nil, ctx: nil)
      unless data = get_event_data(events, ctx: ctx)
        return
      end
      app     = data['app']
      new_ver = data['version']
      return unless should_update?(app, new_ver, ctx: ctx)

      watch_sec = ctx.config.deploy['watch_timeout'] || @@default_timeout
      Timeout.timeout(watch_sec) do |t|
        fetch_update(app, new_ver, ctx: ctx)
      end
    end

    def self.node_name
      @@node_name ||= proc {
        me = Diffusul::Rest.get('/agent/self')
        me['Member']['Name']
      }.call
    end

    def self.get_event_data(events, ctx: nil)
      data = nil
      unless evt = events.last
        ctx.log.debug 'Event not happend yet.'
        return
      end

      evt.each_pair do |key, val|
        if key == 'Payload'
          data = JSON.parse( Base64.decode64(val) )
          ctx.log.debug data.to_s
          break
        end
      end

      unless ctx.config.deploy['apps'][data['app']]
        raise "Not configured app! #{data['app']}"
      end

      data
    end

    def self.should_update?(app, version, ctx: nil)
      node = node_name()
      ver  = Diffusul::Kv.get("#{app}/nodes/#{node}/version", :return)
      if ver == version
        ctx.log.info "App #{app} already updated. version=#{version} Nothing to do."
        return false
      else
        return true
      end
    end

    def self.fetch_update(app, version, ctx: nil)

      updated = false
      while !updated
        nodes = {
          # <hostname> => { semaphore: Str, version: Str }
        }
        Diffusul::Kv.get_recurse("#{app}/nodes/").each do |nd|
          unless %r|#{app}/nodes/([^/]+)/([^/\s]+)$|.match(nd.key)
            ctx.die("Unkwon key pattern! key=#{nd.key}, val=#{nd.value}")
          end
          hostname  = $1
          indicator = $2
          nodes[hostname] ||= {}
          nodes[hostname][indicator] = nd
          ctx.log.debug 'Got node. %s:%s => %s'%[hostname, indicator, nd.value]
        end

        ctx.log.debug nodes.to_s
        candidates = nodes.select do |k,v|
          ctx.log.debug "Node #{k} - Version = #{v['version'].value}, Semaphore=#{v['semaphore'].value}"
          v['version'].value == version && v['semaphore'].value.to_i > 0
        end
        if candidates.empty?
          ctx.die("Can't fetch updated app from any node! app=#{app}, version=#{version}")
        end

        candidates.each_pair do |host, stash|
          unless consume_node(stash['semaphore'])
            ctx.log.debug "Can't get semaphore from #{host}; key=#{stash.key}"
            next
          end

          begin
            fetch_node(host, app: app, version: version, ctx: ctx)
            updated = true
            break
          ensure
            unless restore_node(stash['semaphore'])
              ctx.die("Failed to restore semaphore! app=#{app}, node=#{host}")
            end
          end
        end

        sleep @@loop_interval
      end

    end

    def self.consume_node(sem_kv)
      value = sem_kv.value.to_i - 1
      cas   = sem_kv.modify_index
      Diplomat::Kv.put(sem_kv.key, value.to_s, { cas: cas })
    end

    def self.fetch_node(hostname, app: nil, version: nil, ctx: nil)
      ctx.log.debug "Will update #{app} from #{hostname}."
      kvs = {
        version:   version,
        semaphore: Diffusul::Deploy.get_max_semaphore(ctx: ctx),
      }
      node = node_name()
      kvs.each_pair do |key, val|
        k = "#{app}/nodes/#{node}/#{key}"
        unless Diffusul::Kv.put(k, val.to_s)
          ctx.die("Failed to put kv! key=#{k}, val=#{val}")
        end
      end
      ctx.log.info "[#{node}] Updated app #{app} to version #{version} ."
    end

    def self.restore_node(sem_kv)
      (1..@@restore_retry).each do |i|
        value = Diplomat::Kv.get(sem_kv.key).to_i + 1
        return true if Diplomat::Kv.put(sem_kv.key, value.to_s)
        sleep @@restore_interval
      end
      false
    end
  end
end
