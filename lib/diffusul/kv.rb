require 'diffusul/kv/data'
require 'diffusul/kv/raw'

module Diffusul
  class Kv < Diplomat::Kv
    PREFIX = 'diffusul/'
    @access_methods = [ :get, :put, :delete, :get_data, :get_recurse ]

    def get(key, not_found=:reject, options=nil, found=:return)
      # Notice: change args order to be less coding
      super(PREFIX + key, options, not_found, found)
    end

    # Diplomat::Kv#get returns only string
    def get_data(key, with_prefix: nil)
      path = with_prefix ? '/kv/' + key
           :               "/kv/#{PREFIX}" + key
      begin
        resp = Diffusul::Rest.get(path)
      rescue => e
        Diffusul::Context.get.log.info "Kv data not found. key=#{key}"
        return false
      end
      resp.first do |kv|
        Raw.new(kv).to_data
      end
    end

    # Diplomat::Kv#get with option (:recurse => 1) doesn't work.
    # This is a work around.
    def get_recurse(key)
      list = []
      Diffusul::Rest.get("/kv/#{PREFIX}" + key, params: ['recurse=1']).each do |kv|
        list.push( Raw.new(kv).to_data )
      end
      list
    end

    def put(key, value, options=nil)
      super(PREFIX + key, value, options)
    end

    def delete(key, options=nil)
      super(PREFIX + key, options)
    end

  end
end
