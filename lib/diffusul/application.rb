require 'diffusul/semaphore'
require 'diffusul/version'

module Diffusul
  class Application
    attr :name, :version, :semaphore, :node

    def initialize(name, version: nil, node: nil)
      @name    = name
      @version = version
      @node    = node
    end

    def self.find_or_new(name, node)
      version = Diffusul::Version.get("#{name}/nodes/#{node.name}/version")
      new(name, version: version, node: node)
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
