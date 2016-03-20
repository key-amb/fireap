require 'diplomat'

require 'fireap'
require 'fireap/model/node'
require 'fireap/util/string'

module Fireap::Data
  class Node
    def initialize(stash)
      @me = stash
    end

    def self.find(name)
      raw = Diplomat::Node.get(name)
      new(raw['Node'])
    end

    def get_val(key)
      @me ? @me[key] : nil
    end

    def to_model
      stash = {}
      @me.each_pair do |key, val|
        if key == 'Node'
          stash['name'] = val
        else
          stash[key.to_s.to_snakecase] = val
        end
      end
      Fireap::Model::Node.spawn(stash)
    end
  end
end
