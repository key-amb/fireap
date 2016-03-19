require 'fireap/model/node'
require 'fireap/util/string'

module Fireap::Data
  class Node
    def initialize(stash)
      @me = stash
    end

    def get_val(key)
      @me ? @me[key] : nil
    end

    def to_model
      stash = {}
      @me.each do |key, val|
        stash[key.to_snakecase] = val
      end
      Fireap::Model::Node.spawn(stash)
    end
  end
end
