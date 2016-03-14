require 'curses'

module Fireap
  class Monitor
    class Screen
      def clear
        Curses.clear
        Curses.setpos(0, 0)
      end

      def draw(str)
        Curses.addstr(str)
        Curses.refresh
      end

      def finalize
        Curses.clear
        Curses.close_screen
      end
    end
  end
end
