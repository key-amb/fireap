require 'diffusul/application'
require 'diffusul/nodetable'
require 'diffusul/rest'

module Diffusul
  class Node
    attr :name, :address, :apps

    def initialize(name, address)
      @name    = name
      @address = address
      @apps    = {}
    end

    def self.query_agent_self
      resp = Diffusul::Rest.get('/agent/self')
      new(resp['Member']['Name'], resp['Member']['Address'])
    end
  end
end
