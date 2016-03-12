module Diffusul
  class AppNode
    attr :app, :node, :version, :semaphore

    def initialize(params)
      params.each do |key, val|
        instance_variable_set("@#{key}", val)
      end
    end

    def save(ctx)
      ['version', 'semaphore'].each do |key|
        value   = self.send(key)
        kv_path = "#{self.app}/nodes/#{self.node}/#{key}"
        unless Diffusul::Kv.put(kv_path, value.to_s)
          ctx.die("Failed to put kv! key=#{kv_path}, val=#{value}")
        end
      end
    end
  end
end
