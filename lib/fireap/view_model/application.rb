require 'text-table'

require 'fireap/view_model/application_node'

module Fireap::ViewModel
  class Application
    def initialize(name, ctx)
      @name     = name
      @data     = Fireap::Model::Application.new(name)
      @appnodes = [] # List of ApplicationNode
      @ctx      = ctx
    end

    def refresh
      ntbl = Fireap::Manager::Node.instance
      ntbl.collect_app_info(@data, ctx: @ctx)
      @appnodes = []
      ntbl.nodes.values.each do |node|
        app     = node.apps[@name]
        appnode = Fireap::ViewModel::ApplicationNode.new(app, node)
        @appnodes.push(appnode)
      end
    end

    def render_text
      text =  header_text()
      text << body_text()
    end

    private

    def header_text
      <<"EOH"
----
Time: #{Time.now}
App:  "#{@name}"
----
EOH
    end

    def body_text
      tt = Text::Table.new
      tt.head = %w[ Name Version Sem Date From ]

      @appnodes.sort.each do |an|
        tt.rows << [
          an.nodename,
          an.version,
          an.semaphore,
          an.updated_at,
          an.remote_node,
        ]
      end

      @body = tt.to_s
    end
  end
end
