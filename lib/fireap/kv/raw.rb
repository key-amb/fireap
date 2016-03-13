require 'base64'

require 'fireap/kv/data'

module Fireap
  class Kv < Diplomat::Kv
    class Raw
      @me = nil
      def initialize(kv)
        @me = kv
      end

      def to_data
        data = {}
        @me.each do |key, val|
          if key == 'Value'
            data[key.to_snake] = Base64.decode64(val)
          else
            data[key.to_snake] = val
          end
        end
        Fireap::Kv::Data.new(data)
      end
    end
  end
end
