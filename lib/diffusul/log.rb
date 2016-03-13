module Diffusul
  class Log
    attr :ctx

    def initialize(logger, dry_run: nil, develop_mode: nil)
      @log = logger
      @dry_run = dry_run
      @develop_mode = develop_mode
    end

    def method_missing(method, *args)
      lg_args = args
      msg = lg_args.shift
      if @dry_run
        msg = "[Dry-run] #{msg}"
      end
      if @develop_mode
        msg = "## DEVELOP MODE ## #{msg}"
      end
      @log.send(method, msg, *lg_args)
    end
  end
end
