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

    def get_or_newapp(name)
      self.apps[name] ||= Diffusul::Application.find_or_new(name, self)
    end
  end
end
