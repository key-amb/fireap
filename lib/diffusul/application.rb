module Diffusul
  class Application
    attr :name, :version, :semaphore, :node

    def initialize(name, version: nil, node: nil)
      @name    = name
      @version = version
      @node    = node
    end

    def self.find_or_new(name, node)
      version = Diffusul::Kv.get("#{name}/nodes/#{node.name}/version", :return) || 0
      new(name, version: version, node: node)
    end

    def set_kv_prop(key, kv_data)
      @version = kv_data.value if (key == 'version')
      if (key == 'semaphore')
        @semaphore = Diffusul::Semaphore.new(kv_data)
      end
    end
  end
end

