require 'fireap/model/command'

module Fireap::Model

  # A Job is defined by set of Commands.
  # @see Fireap::Model::Command
  # @todo Currently this class suppose that Fireap::Context object is given.
  #  It should be more isolative from context.

  class Job
    attr :ctx
    def initialize(ctx: nil)
      @ctx = ctx
    end

    def run_commands(app: nil, remote: nil)
      app_cfg = @ctx.config.app_config(app.name)
      formats = app_cfg.commands \
        or "No command configured! app=#{app.name}"

      @results = []
      formats.each do |fmt|
        command = Fireap::Model::Command.new(
          app:    app.name,
          format: fmt,
          remote: remote,
          config: app_cfg,
          ctx:    @ctx,
        )
        result = command.run
        @results.push(result)

        if result.is_failed?
          if app_cfg.is_failure_ignored?
            @ctx.log.warn "[#{app}] Failure IGNORE is ON. Going on."
            result.mark_ignored
            next
          else
            @ctx.log.error "[#{app}] ABORT because Failed!"
            break unless @ctx.develop_mode?
          end
        end
      end

      @results
    end
  end
end
