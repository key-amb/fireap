module Fireap::Model
  ##
  # A data model which has info of a particular Application and a Node.
  class ApplicationNode
    attr :app, :node, :appname, :nodename

    # @param app  [Fireap::Model::Application]
    # @param node [Fireap::Model::Node]
    # @param ctx  [Fireap::Context]
    def initialize(app, node, ctx: nil)
      @app  = app
      @node = node
      @ctx  = ctx
      @appname  = app.name
      @nodename = node.name
    end

    # @return [Array(Fireap::Model::ApplicationNode)]
    def find_updated_nodes(version)
      ntable = Fireap::Manager::Node.instance
      ntable.collect_app_info(@app, ctx: @ctx)

      found = []
      nodes = ntable.select_updated(@app, version, ctx: @ctx)
      nodes.each_pair do |host, node|
        if @nodename == host
          @ctx.log.info "Candidate node is myself. #{host} Skip."
          next unless @ctx.develop_mode?
        end
        found.push( self.class.new(node.apps[@appname], node, ctx: @ctx) )
      end
      found
    end
  end
end
