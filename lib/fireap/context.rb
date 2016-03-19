require 'data/validator'

require 'fireap/logger'
require 'fireap/util/validator'

module Fireap
  class Context
    include Fireap::Util::Validator

    attr :config, :log
    @node = nil # Fireap::Model::Node of running host
    @mode = 'production'

    def initialize(*args)
      params = ::Data::Validator.new(
        config_path:  { isa: [String, NilClass], default: nil },
        dry_run:      { isa: BOOL_FAMILY, default: nil },
        suppress_log: { isa: BOOL_FAMILY, default: nil },
        develop_mode: { isa: BOOL_FAMILY, default: nil },
      ).validate(*args)

      cfg = {}
      cfg[:path] = params[:config_path] if params[:config_path]
      @config    = Fireap::Config.new(cfg)
      @dry_run   = params[:dry_run]
      @mode      = 'develop' if params[:develop_mode]
      @log       = logger(@config.log, params[:suppress_log])
    end

    def die(message, level=::Logger::ERROR, err=Fireap::Error)
      @log.log(level, [message, 'at', caller(1).to_s].join(%q{ }))
      raise err, message unless self.develop_mode?
    end

    def mynode
      @node ||= Fireap::Model::Node.query_agent_self
    end

    def dry_run?
      @dry_run
    end

    def develop_mode?
      if is_develop_mode?
        @log.warn 'IN DEVELOP MODE. Called from ' + caller(1..2).to_s if @log
        true
      else
        false
      end
    end

    private

    def logger(config, suppress)
      outs = []
      unless suppress
        outs.push(STDOUT) if STDOUT.tty?
        outs.push(config['file']) if config['file']
      end
      headers = []
      headers.push('## DEVELOP MODE ##') if is_develop_mode?
      headers.push('[Dry-run]')          if dry_run?
      Fireap::Logger.new(
        outs, rotate: config['rotate'], level: config['level'], header: headers.join(%q[ ])
      )
    end

    def is_develop_mode?
          @mode == 'develop' \
      and flg = @config.enable_debugging \
      and flg != 0 and flg.length > 0
    end
  end
end
