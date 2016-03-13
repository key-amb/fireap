require 'diffusul/application'
require 'diffusul/rest'

module Diffusul
  class Node
    attr :name, :apps

    def initialize(name=nil)
      @name = name || proc {
        resp = Diffusul::Rest.get('/agent/self')
        resp['Member']['Name']
      }.call
      @apps = {}
    end
  end
end
