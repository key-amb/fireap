require 'terminal-table'

module Fireap::ViewModel
  class Config

    def initialize(width: nil)
      @cmdwidth = width || 90
    end

    # @param list [Array] of Fireap::Config::App objects
    def render_applist(list)
      text = "[Summary]\n"
      text << render_applist_summary(list)
      text << "\n"
      text << render_applist_commands(list)
    end

    private

    # @param list [Array] of Fireap::Config::App objects
    def render_applist_summary(list)
      tt = Terminal::Table.new
      tt.headings = %w[ App MaxSem Timeout OnCmdFail Service Tag WaitAfterFire ]
      list.each do |conf|
        app = conf.to_view
        tt.add_row [
          app.name,
          app.max_semaphores,
          '%d sec' % [app.watch_timeout],
          app.is_failure_ignored ? 'IGNORE' : 'ABORT',
          app.service_filter,
          app.tag_filter,
          '%d sec' % [app.wait_after_fire],
        ]
      end
      tt.to_s
    end

    # @param list [Array] of Fireap::Config::App objects
    def render_applist_commands(list)
      text = ''
      list.each do |conf|
        app = conf.to_view
        text << %Q|[App "#{app.name}" - Commands]\n|
        text << render_app_commands(conf)
        text << "\n"
      end
      text
    end

    def render_app_commands(app)
      tt = Terminal::Table.new
      tt.headings = %w[ # Command ]
      app.commands.each_with_index do |cmd, i|
        cmds = cmd.scan(/.{1,#{@cmdwidth}}/)
        tt.add_row [ i+1, cmds.join("\n") ]
      end
      tt.to_s
    end

    # ViewModel of Fireap::Config::App
    class App
      def initialize(stash)
        @me = stash
      end

      def method_missing(method)
        if @me.has_key?(method.to_s)
          @me[method.to_s]
        end
      end
    end
  end
end
