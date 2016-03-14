require 'text-table'

module Fireap
  class Monitor
    class Display
      def initialize(appname, nodes)
        @appname = appname
        @nodes   = nodes
      end

      def show
        puts content()
      end

      def content
        header() + body()
      end

      def update(appname, nodes)
        @appname = appname
        @nodes   = nodes
      end

      private

      def body
        tt = Text::Table.new
        tt.head = %w[ Name Version Sem Date From ]

        @nodes.each do |n|
          nap  = n.apps[@appname]
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
        @header = <<"EOH"
----
Time: #{Time.now}
App:  "#{@appname}"
----
EOH
      end
    end
  end
end
