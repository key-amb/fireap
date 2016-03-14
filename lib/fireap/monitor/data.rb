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
        ntbl.nodes.values
      end
    end
  end
end
