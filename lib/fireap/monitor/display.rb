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
          tt.rows << [
            n[:name],
            n[:version]     || '-',
            n[:semaphore]   || '-',
            n[:update_at]   || '-',
            n[:remote_node] || '-',
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
