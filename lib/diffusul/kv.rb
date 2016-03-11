module Diffusul
  class Kv < Diplomat::Kv
    @@prefix = 'diffusul/'
    @access_methods = [ :get, :put, :delete ]

    def get(key, not_found=:reject, options=nil, found=:return)
      # Notice: change args order to be less coding
      super(@@prefix + key, options, not_found, found)
    end

    def put(key, value, options=nil)
      super(@@prefix + key, value, options)
    end

    def delete(key, options=nil)
      super(@@prefix + key, options)
    end
  end
end
