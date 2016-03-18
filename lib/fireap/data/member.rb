require 'diplomat'

require 'fireap'
require 'fireap/model/member'
require 'fireap/util/string'

module Fireap::Data
  class Member
    @me = nil
    def initialize(stash)
      @me = stash
    end

    def self.get_all
      Diplomat::Members.get
    end

    def to_model
      stash = {}
      @me.each do |key, val|
        stash[key.to_snakecase] = val
      end
      Fireap::Model::Member.new(stash)
    end
  end
end
