require 'diffusul/semaphore'
require 'diffusul/version'

module Diffusul
  class Application
    attr :name, :version, :semaphore, :node

    def initialize(name, version: nil, semaphore: nil, node: nil)
      @name      = name
      @version   = version
      @semaphore = semaphore
      @node      = node
    end

    def self.find_or_new(name, node)
      app  = new(name, node: node)
      path = "#{name}/nodes/#{node.name}"
      kv_data = Diffusul::Kv.get_recurse(path)
      if kv_data.length > 0
        kv_data.each { |kv| app.set_kv_prop(File.basename(kv.key), kv) }
      else
        %w[version semaphore].each do |key|
          app.set_kv_prop(key, Diffusul::Kv::Data.new({
            key: Diffusul::Kv::PREFIX + [path, key].join('/'),
          }))
        end
      end
      app
    end

    def set_kv_prop(key, kv_data)
      case key
      when 'version'
        @version = Diffusul::Version.new(kv_data.to_hash)
      when 'semaphore'
        @semaphore = Diffusul::Semaphore.new(kv_data.to_hash)
      else
        raise "Unkwon kv_prop! key=#{key}, data=#{kv_data.to_s}"
      end
    end
  end
end
