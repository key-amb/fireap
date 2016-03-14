require 'text-table'

require 'fireap/kv'

module Fireap
  class Monitor

    def initialize(options, ctx: nil)
      @app = options['app']
      @ctx = ctx
    end

    def capture(options)
      ntbl = Fireap::NodeTable.instance
      app_i = Fireap::Application.new(@app)
      ntbl.collect_app_info(app_i, ctx: @ctx)

      disp = Display.new(@app, ntbl.nodes.values.sort)
      disp.show
    end

    class Display
      def initialize(app, nodes)
        @app   = app
        @nodes = nodes
      end

      def show
        puts header()
        puts body()
      end

      private

      def body
        return @body if @body

        tt = Text::Table.new
        tt.head = %w[ Name Version Sem Date From ]

        @nodes.each do |n|
          nap  = n.apps[@app]
          last = nap.update_info
          tt.rows << [
            n.name,
            nap.version.value   || '-',
            nap.semaphore.value || '-',
            last.updated_at     || '-',
            last.remote_node    || '-',
          ]
        end

        @body = tt.to_s
      end

      def header
        @header ||= <<"EOH"
----
App: "#{@app}"
----
EOH
      end
    end
  end
end
