require 'fireap/kv'
require 'fireap/monitor/data'
require 'fireap/monitor/display'
require 'fireap/monitor/screen'

module Fireap
  class Monitor

    def initialize(options, ctx: nil)
      @appname  = options['app']
      @data     = Data.new(options['app'], ctx: ctx)
      @interval = 1
      @ctx      = ctx
    end

    def monitor(options)
      @screen = Screen.new

      int = 0
      Signal.trap(:INT) { int = 1 }

      disp = Display.new(@appname, DataUtil.sort(@data.fetch))
      while int == 0
        @screen.clear
        @screen.draw(disp.content)
        sleep @interval
        disp.update(@appname, DataUtil.sort(@data.fetch))
      end

      @screen.finalize

      puts "End."
    end

    def capture(options)
      disp = Display.new(@appname, DataUtil.sort(@data.fetch))
      disp.show
    end

    module DataUtil
      module_function
      def sort(nodes)
        nodes.sort do |a,b|
          ret = b[:version] <=> a[:version]
          ret == 0 ? a[:name] <=> b[:name] : ret
        end
      end
    end
  end
end
