require 'singleton'

require 'fireap'

module Fireap::Util
  class Consul
    include Singleton
    @@member_status_name2code = {
      alive:   1,
      left:    3,
      failing: 4,
      __unknown__: -1,
    }

    class << self
      # @param key [Symbol] Consul member status name like "alive", "failing" and so on.
      # @return [Fixnum] Status number
      def member_status_name2code(key)
        @@member_status_name2code[key] || proc {
          warn "Unkwon Status! key=#{key}"
          return @@member_status_name2code[:__unknown__]
        }.call
      end

      # @param code [Fixnum] Consul member status code
      # @return [Symbol] Status name
      def member_status_code2name(code)
        @@member_status_name2code.each_pair do |key, val|
          return key if val == code
        end
        return :__unknown__
      end
    end
  end
end
