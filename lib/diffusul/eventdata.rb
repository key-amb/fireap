require 'base64'
require 'json'

require 'diffusul/string'

module Diffusul
  class EventData
    attr :id, :name, :payload, :node_filter, :service_filter, :tag_filter, :version, :ltime

    def initialize(data)
      data.each_pair do |k,v|
        if k == 'Payload'
          v = JSON.parse( Base64.decode64(v) )
        end
        instance_variable_set("@#{k.to_snake}", v)
      end
    end

    def self.create_by_streams(text)
      JSON.parse(text).map { |d| new(d) }
    end
  end
end
