require 'diffusul/kv/data'

module Diffusul
  class Semaphore < Diffusul::Kv::Data
    def consume(cas: false)
      if @value <= 0
        raise "No more semaphore! val=#{@value}"
      end
      self.update(@value - 1, cas: cas)
    end

    def restore(cas: false)
      self.update(@value + 1, cas: cas)
    end
  end
end
