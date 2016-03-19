require 'diplomat'

require 'fireap'
require 'fireap/data/node'
require 'fireap/data_access/service'

module Fireap::Manager
  class NodeFactory
    class << self
      def catalog_service_by_filter(service_filter, tag_filter: nil)
        nodes = []
        svc_regexp = Regexp.new(service_filter)
        tag_regexp = tag_filter ? Regexp.new(tag_filter) : nil
        service_catalog = Fireap::DataAccess::Service.catalog_all
        service_catalog.each_pair do |svc, tags|
          next unless svc_regexp.match(svc)
          if tags.length > 0
            tags.each do |t|
              next if tag_regexp && ! tag_regexp.match(t)
              nodes.concat( catalog_service(svc, tag: t) )
            end
          elsif ! tag_regexp
            nodes.concat( catalog_service(svc) )
          else # tag_filter specified, but no tag found
            next
          end
        end
        nodes
      end

      def catalog_service(service, tag: nil)
        opt = { tag: tag }
        data = Diplomat::Service.get(service, :all, opt)
        return nil unless data
        data.map { |d| Fireap::Data::Node.new(d).to_model }
      end
    end
  end
end
