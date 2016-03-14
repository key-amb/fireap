require 'fireap/application'
require 'fireap/nodetable'

module Fireap
  class Monitor
    class Data
      def initialize(app, ctx: nil)
        @app = Fireap::Application.new(app)
        @ctx = ctx
      end

      def fetch
        ntbl  = Fireap::NodeTable.instance
        ntbl.collect_app_info(@app, ctx: @ctx)
        ntbl.nodes.values.map do |n|
          nap  = n.apps[@app.name]
          last = nap.update_info
          {
            name:        n.name,
            version:     nap.version.value,
            semaphore:   nap.semaphore.value,
            update_at:   last ? last.updated_at  : nil,
            remote_node: last ? last.remote_node : nil,
          }
        end
      end
    end
  end
end
