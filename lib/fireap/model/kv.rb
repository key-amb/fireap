require 'diplomat'

require 'fireap'
require 'fireap/data_access/kv'
require 'fireap/util/string'

module Fireap::Model
  class Kv
    @@accessors = [
      :key, :value, :create_index, :modify_index,
      :lock_index, :flags, :session, :is_dirty
    ]
    @@accessors.each do |key|
      attr key
    end

    def initialize(params)
      params.each do |key, val|
        instance_variable_set("@#{key}", val)
      end
      @is_dirty = false
    end

    def self.get(path)
      Fireap::DataAccess::Kv.get_data(path) || new({
        key: Fireap::Kv::PREFIX + path,
      })
    end

    def to_hash
      stash = {}
      @@accessors.each do |key|
        stash[key] = instance_variable_get("@#{key}")
      end
      stash
    end

    # Query Kv and return the new instance
    def refetch
      Fireap::DataAccess::Kv.get_data(self.key, with_prefix: true)
    end

    def update(value, cas: false)
      before = @value
      updated = proc {
        @value = value.to_s
        save(cas: cas)
      }.call
      if updated
        # Set dirty flag because @modiry_index is unreliable now.
        @is_dirty = true
        true
      else
        @value = before
        false
      end
    end

    def save(cas: false)
      args = [self.key, self.value]
      args.push({ cas: self.modify_index }) if cas
      if Diplomat::Kv.put(*args)
        return true
      end
      false
    end
  end
end
