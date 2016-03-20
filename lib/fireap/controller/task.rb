require 'fireap'
require 'fireap/view_model/config'

module Fireap::Controller
  class Task

    # @param ctx [Fireap::Context]
    def show(options, ctx)
      renderer = Fireap::ViewModel::Config.new(width: options['width'])
      list = ctx.config.app_list
      puts '== Configured Tasks =='
      puts renderer.render_applist(list)
    end
  end
end
