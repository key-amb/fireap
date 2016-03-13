require 'diffusul/kv/data'

module Diffusul
  class Semaphore < Diffusul::Kv::Data
    def consume(cas: false)
      if @value.to_i <= 0
        raise "No more semaphore! val=#{@value}"
      end
      self.update(@value.to_i - 1, cas: cas)
    end

    def restore(cas: false)
      self.update(@value.to_i + 1, cas: cas)
    end

    def refetch
      self.class.new(super.to_hash)
    end
  end
end
