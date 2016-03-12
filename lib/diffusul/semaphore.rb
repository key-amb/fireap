module Diffusul
  class Semaphore
    attr :key, :value, :index

    def initialize(kv)
      @key   = kv.key
      @value = kv.value.to_i
      @index = kv.modify_index
    end

    def consume(cas: false)
      self.save(self.value - 1, cas: cas)
    end

    def renew
      @value = Diplomat::Kv.get(self.key).to_i
    end

    def restore(cas: false)
      self.save(self.value + 1, cas: cas)
    end

    def save(value, cas: false)
      args = [self.key, value]
      args.push({ cas: self.index }) if cas
      if Diplomat::Kv.put(self.key, value.to_s)
        @value = value.to_i
        return true
      end
      false
    end
  end
end

