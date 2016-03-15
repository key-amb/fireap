require 'fireap/kv/data'
require 'fireap/kv/raw'

module Fireap::DataAccess
  class Kv < Diplomat::Kv
    PREFIX = 'fireap/'
    @access_methods = [ :get, :put, :delete, :get_data, :get_recurse ]

    def get(key, not_found=:reject, options=nil, found=:return)
      # Notice: change args order to be less coding
      super(PREFIX + key, options, not_found, found)
    end

    # Diplomat::Kv#get returns only string
    def get_data(key, with_prefix: nil)
      path = with_prefix ? '/kv/' + key
           :               "/kv/#{PREFIX}" + key
      unless resp = Fireap::Rest.get(path)
        return false
      end
      Raw.new(resp.shift).to_data
    end

    # Diplomat::Kv#get with option (:recurse => 1) doesn't work.
    # This is a work around.
    def get_recurse(key)
      unless resp = Fireap::Rest.get("/kv/#{PREFIX}" + key, params: ['recurse=1'])
        return []
      end
      resp.map { |kv| Raw.new(kv).to_data }
    end

    def put(key, value, options=nil)
      super(PREFIX + key, value, options)
    end

    def delete(key, options=nil)
      super(PREFIX + key, options)
    end
  end
end
