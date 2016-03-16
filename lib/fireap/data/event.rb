require 'base64'
require 'json'

require 'fireap/model/event'
require 'fireap/util/string'

module Fireap::Data
  class Event
    @me = nil
    def initialize(stash)
      @me = stash
    end

    def to_model
      stash = {}
      @me.each do |key, val|
        if key == 'Payload' && val
          stash[key.to_snakecase] = JSON.parse( Base64.decode64(val) )
        else
          stash[key.to_snakecase] = val
        end
      end
      Fireap::Model::Event.new(stash)
    end
  end
end
