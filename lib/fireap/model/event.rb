require 'base64'
require 'diplomat'
require 'json'

require 'fireap'
require 'fireap/data/event'

module Fireap::Model
  class Event
    attr :id, :name, :payload, :node_filter, :service_filter, :tag_filter, :version, :ltime

    def initialize(stash)
      stash.each do |key, val|
        instance_variable_set("@#{key}", val)
      end
      @name ||= Fireap::EVENT_NAME
    end

    def self.fetch_from_stdin
      streams = ''
      while ins = $stdin.gets
        streams << ins
      end

      events = convert_from_streams(streams)
      return unless events.length > 0
      events.last
    end

    # @param text [String] JSON text containing Event data list
    # @return [Array[Fireap::Model::Event]]
    def self.convert_from_streams(text)
      JSON.parse(text).map do |stash|
        Fireap::Data::Event.new(stash).to_model
      end
    end

    def fire
      Diplomat::Event.fire(self.name, self.payload.to_json)
    end
  end
end
