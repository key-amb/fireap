require 'json'

require 'fireap/semaphore'
require 'fireap/version'

module Fireap
  class Application
    attr :name, :version, :semaphore, :node, :update_info

    def initialize(name, version: nil, semaphore: nil, node: nil)
      @name      = name
      @version   = version
      @semaphore = semaphore
      @node      = node
      @update_info = nil
    end

    def self.find_or_new(name, node)
      app     = new(name, node: node)
      path    = "#{name}/nodes/#{node.name}"
      kv_data = Fireap::DataAccess::Kv.get_recurse(path)
      if kv_data.length > 0
        kv_data.each { |kv| app.set_kv_prop(File.basename(kv.key), kv) }
      end
      %w[version semaphore update_info].each do |key|
        unless app.instance_variable_get("@#{key}")
          app.set_kv_prop(key, Fireap::Kv::Data.new({
            key: Fireap::Kv::PREFIX + [path, key].join('/'),
          }))
        end
      end
      app
    end

    def to_hash
      {
        name:        @name,
        version:     @version     ? @version.value : '0',
        semaphore:   @semaphore   ? @semaphore.value : '0',
        update_at:   @update_info ? @update_info.updated_at : nil,
        remote_node: @update_info ? @update_info.remote_node : nil,
      }
    end

    def set_kv_prop(key, kv_data)
      case key
      when 'version'
        @version = Fireap::Version.new(kv_data.to_hash)
      when 'semaphore'
        @semaphore = Fireap::Semaphore.new(kv_data.to_hash)
      when 'update_info'
        @update_info = Fireap::Application::UpdateInfo.new(kv_data.to_hash)
      else
        raise "Unkwon kv_prop! key=#{key}, data=#{kv_data.to_s}"
      end
    end

    class UpdateInfo < Fireap::Kv::Data
      attr :updated_at, :remote_node

      def initialize(params)
        super(params)
        return unless @value
        JSON.parse(@value).tap do |v|
          @updated_at  = v['updated_at']
          @remote_node = v['remote_node']
        end
      end
    end
  end
end
