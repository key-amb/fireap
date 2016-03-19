require 'fireap/manager/node'
require 'fireap/model/application'
require 'fireap/data_access/rest'

module Fireap::Model
  class Node
    attr :name, :address, :apps

    def initialize(name, address)
      @name    = name
      @address = address
      @apps    = {}
    end

    def self.spawn(stash)
      me = new( stash.delete('name'), stash.delete('address') )
      stash.each do |key, val|
        me.instance_variable_set("@#{key}", val)
      end
      me
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
