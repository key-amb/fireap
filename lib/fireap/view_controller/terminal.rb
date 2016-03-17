require 'curses'

module Fireap::ViewController
  class Terminal
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
