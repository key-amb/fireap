module Diffusul
  class Kv < Diplomat::Kv
    @@prefix = 'diffusul/'
    @access_methods = [ :get, :put, :delete, :get_data, :get_recurse ]

    def get(key, not_found=:reject, options=nil, found=:return)
      # Notice: change args order to be less coding
      super(@@prefix + key, options, not_found, found)
    end

    # Diplomat::Kv#get returns only string
    def get_data(key)
      Diffusul::Rest.get("/kv/#{@@prefix}" + key).first do |kv|
        Data.spawn(kv)
      end
    end

    # Diplomat::Kv#get with option (:recurse => 1) doesn't work.
    # This is a work around.
    def get_recurse(key)
      list = []
      Diffusul::Rest.get("/kv/#{@@prefix}" + key, params: ['recurse=1']).each do |kv|
        list.push( Data.spawn(kv) )
      end
      list
    end

    def put(key, value, options=nil)
      super(@@prefix + key, value, options)
    end

    def delete(key, options=nil)
      super(@@prefix + key, options)
    end

    class Data
      attr :key, :value, :create_index, :modify_index, :lock_index, :flags, :session

      def initialize(params)
        params.each do |key, val|
          instance_variable_set("@#{key}", val)
        end
      end

      def self.spawn(raw)
        params = {}
        raw.each do |key, val|
          if key == 'Value'
            params[key.to_snake] = Base64.decode64(val)
          else
            params[key.to_snake] = val
          end
        end
        new(params)
      end
    end
  end
end
