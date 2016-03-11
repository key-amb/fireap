module Diffusul
  class Kv < Diplomat::Kv
    @@prefix = 'diffusul/'
    @access_methods = [ :get, :put, :delete, :get_recurse ]

    def get(key, not_found=:reject, options=nil, found=:return)
      # Notice: change args order to be less coding
      super(@@prefix + key, options, not_found, found)
    end

    # Diplomat::Kv#get with option (:recurse => 1) doesn't work.
    # This is a work around.
    def get_recurse(key)
      list = []
      Diffusul::Rest.get("/kv/#{@@prefix}" + key, params: ['recurse=1']).each do |kv|
        list.push({ key: kv['Key'], value: Base64.decode64(kv['Value']) })
      end
      list
    end

    def put(key, value, options=nil)
      super(@@prefix + key, value, options)
    end

    def delete(key, options=nil)
      super(@@prefix + key, options)
    end
  end
end
