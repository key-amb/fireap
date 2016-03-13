module Fireap
  class Log
    attr :ctx

    def initialize(logger, dry_run: nil, develop_mode: nil)
      @log = logger
      @dry_run = dry_run
      @develop_mode = develop_mode
    end

    def method_missing(method, *args)
      lg_args = args
      if %w[ debug info warn error fatal ].include?(method)
        msg = lg_args[0]
        if @dry_run
          msg = "[Dry-run] #{msg}"
        end
        if @develop_mode
          msg = "## DEVELOP MODE ## #{msg}"
        end
      end
      @log.send(method, *lg_args)
    end
  end
end
