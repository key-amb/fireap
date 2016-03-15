require 'fireap/application'
require 'fireap/manager/node'
require 'fireap/data_access/rest'

module Fireap::Model
  class Node
    attr :name, :address, :apps

    def initialize(name, address)
      @name    = name
      @address = address
      @apps    = {}
    end

    def self.query_agent_self
      resp = Fireap::DataAccess::Rest.get('/agent/self')
      new(resp['Member']['Name'], resp['Member']['Address'])
    end

    def has_app?(appname)
      @apps[appname] ? true : false
    end
  end
end
