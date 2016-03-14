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

      disp = Display.new(@appname, @data.fetch.sort)
      while int == 0
        @screen.clear
        @screen.draw(disp.content)
        sleep @interval
        disp.update(@appname, @data.fetch.sort)
      end

      @screen.finalize

      puts "End."
    end

    def capture(options)
      list = @data.fetch
      disp = Display.new(@appname, list.sort)
      disp.show
    end
  end
end
