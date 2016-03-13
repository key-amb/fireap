require 'diffusul/kv/data'

module Diffusul
  class Version < Diffusul::Kv::Data
    def initialize(params)
      super(params)
      @value ||= '0'
    end

    def next_version
      if %r{(.*\D)?(\d+)(\D*)?}.match(@value.to_s)
        [$1, $2.to_i + 1, $3].join
      else
        @value + '-1'
      end
    end
  end
end
