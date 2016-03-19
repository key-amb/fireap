require 'base64'

require 'fireap/model/kv'
require 'fireap/util/string'

module Fireap::Data
  class Kv
    def initialize(kv)
      @me = kv
    end

    def to_model
      data = {}
      @me.each do |key, val|
        if key == 'Value' && val
          data[key.to_snakecase] = Base64.decode64(val)
        else
          data[key.to_snakecase] = val
        end
      end
      Fireap::Model::Kv.new(data)
    end
  end
end
