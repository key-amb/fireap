require 'fireap/application'
require 'fireap/manager/node'
require 'fireap/rest'

module Fireap
  class Node
    attr :name, :address, :apps

    def initialize(name, address)
      @name    = name
      @address = address
      @apps    = {}
    end

    def self.query_agent_self
      resp = Fireap::Rest.get('/agent/self')
      new(resp['Member']['Name'], resp['Member']['Address'])
    end

    def has_app?(appname)
      @apps[appname] ? true : false
    end
  end
end
