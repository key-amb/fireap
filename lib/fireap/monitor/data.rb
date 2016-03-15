require 'fireap/application'
require 'fireap/manager/node'

module Fireap
  class Monitor
    class Data
      def initialize(app, ctx: nil)
        @app = Fireap::Application.new(app)
        @ctx = ctx
      end

      def fetch
        ntbl  = Fireap::Manager::Node.instance
        ntbl.collect_app_info(@app, ctx: @ctx)
        ntbl.nodes.values.map do |n|
          nodeh = { name: n.name }
          apph  = n.apps[@app.name].to_hash
          apph.merge(nodeh)
        end
      end
    end
  end
end
