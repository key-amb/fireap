require 'data/validator'
require 'json'

require 'fireap'
require 'fireap/data_access/kv'
require 'fireap/model/kv'
require 'fireap/model/node'

module Fireap::Model

  # A data container of an Application and related information.
  # @todo Ideally it should belong to a Node object. So this object should not
  #  include @node
  #  If you want to treat Application and Node, use Fireap::Mode::ApplicationNode
  # @see Fireap::Model::ApplicationNode

  class Application
    attr :name, :version, :semaphore, :node, :update_info

    def initialize(name, *option)
      args = { name: name }
      args.merge!(*option) if ! option.empty?
      params = Data::Validator.new(
        name:      { isa: String },
        version:   { isa: Version,             default: nil },
        semaphore: { isa: Semaphore,           default: nil },
        node:      { isa: Fireap::Model::Node, default: nil },
      ).validate(args)

      params.each_pair do |key, val|
        instance_variable_set("@#{key}", val)
      end
      @update_info = nil
    end

    # @todo Move this to Fireap::Model::ApplicationNode
    def self.find_or_new(name, node)
      app     = new(name, node: node)
      path    = "#{name}/nodes/#{node.name}"
      kv_data = Fireap::DataAccess::Kv.get_recurse(path)
      if kv_data.length > 0
        kv_data.each { |kv| app.set_kv_prop(File.basename(kv.key), kv) }
      end
      %w[version semaphore update_info].each do |key|
        unless app.instance_variable_get("@#{key}")
          app.set_kv_prop(key, Fireap::Model::Kv.new({
            key: Fireap::Kv::PREFIX + [path, key].join('/'),
          }))
        end
      end
      app
    end

    def to_hash
      {
        name:        @name,
        version:     @version     ? @version.value   : '0',
        semaphore:   @semaphore   ? @semaphore.value : '0',
        update_at:   @update_info ? @update_info.updated_at : nil,
        remote_node: @update_info ? @update_info.remote_node : nil,
      }
    end

    def set_kv_prop(key, kv_data)
      case key
      when 'version'
        @version = Version.new(kv_data.to_hash)
      when 'semaphore'
        @semaphore = Semaphore.new(kv_data.to_hash)
      when 'update_info'
        @update_info = UpdateInfo.new(kv_data.to_hash)
      else
        raise "Unkwon kv_prop! key=#{key}, data=#{kv_data.to_s}"
      end
    end

    def update_properties(version: nil, semaphore: nil, cas: nil, remote_node: nil)
      updated = 0
      if version and @version.update(version)
        updated += 1
      end
      if semaphore and @semaphore.update(semaphore, cas: cas)
        updated += 1
      end
      if remote_node
        ret = @update_info.update({
          updated_at: Time.now.to_s, remote_node: remote_node
        }.to_json)
        updated += 1 if ret
      end
      updated
    end

    class Version < Fireap::Model::Kv
      def initialize(params)
        super(params)
        @value ||= '0'
      end

      def next_version
        if %r{(.*\D)?(\d+)(\D*)?}.match(@value.to_s)
          [$1, $2.to_i + 1, $3].join
        else
          @value + '-1'
        end
      end
    end

    class Semaphore < Fireap::Model::Kv
      def consume(cas: false)
        if @value.to_i <= 0
          raise "No more semaphore! val=#{@value}"
        end
        self.update(@value.to_i - 1, cas: cas)
      end

      def restore(cas: false)
        self.update(@value.to_i + 1, cas: cas)
      end

      def refetch
        self.class.new(super.to_hash)
      end
    end

    class UpdateInfo < Fireap::Model::Kv
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
