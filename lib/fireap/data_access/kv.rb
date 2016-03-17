require 'fireap'
require 'fireap/model/kv'
require 'fireap/data/kv'

module Fireap::DataAccess
  class Kv < Diplomat::Kv
    @@prefix = Fireap::Kv::PREFIX
    @access_methods = [ :get, :put, :delete, :get_data, :get_recurse ]

    def get(key, not_found=:reject, options=nil, found=:return)
      # Notice: change args order to be less coding
      super(@@prefix + key, options, not_found, found)
    end

    # Diplomat::Kv#get returns only string
    def get_data(key, with_prefix: nil)
      path = with_prefix ? '/kv/' + key
           :               "/kv/#{@@prefix}" + key
      unless resp = Fireap::DataAccess::Rest.get(path)
        return false
      end
      Fireap::Data::Kv.new(resp.shift).to_model
    end

    # Diplomat::Kv#get with option (:recurse => 1) doesn't work.
    # This is a work around.
    def get_recurse(key)
      unless resp = Fireap::DataAccess::Rest.get("/kv/#{@@prefix}" + key, params: ['recurse=1'])
        return []
      end
      resp.map { |kv| Fireap::Data::Kv.new(kv).to_model }
    end

    def put(key, value, options=nil)
      super(@@prefix + key, value, options)
    end

    def delete(key, options=nil)
      super(@@prefix + key, options)
    end
  end
end
