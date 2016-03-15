require 'logger'

module Fireap
  class Context
    attr :config, :log
    @node = nil # Fireap::Model::Node of running host
    @mode = 'production'

    def initialize(config_path: nil, dry_run: nil, develop_mode: nil)
      cfg = {}
      cfg[:path] = config_path if config_path
      @config    = Fireap::Config.new(cfg)
      @dry_run   = dry_run
      @mode      = 'develop' if develop_mode
      @log       = logger(@config.log)
    end

    def die(message, level=Logger::ERROR, err=Fireap::Error)
      p message
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
      if    @mode == 'develop' \
        and flg = @config.enable_debugging \
        and flg != 0 and flg.length > 0
        @log.warn 'IN DEVELOP MODE. Called from ' + caller(1..2).to_s
        true
      else
        false
      end
    end

    private

    def logger(config)
      dest   = config['file']   || STDOUT
      rotate = config['rotate'] || 0
      level  = config['level']  || 'INFO'
      @log   = Logger.new(dest, rotate)
      @log.level = Object.const_get("Logger::#{level}")
      @log.formatter = proc do |level, date, prog, msg|
        "#{date} [#{level}] #{msg} -- #{prog}\n"
      end
      @log
    end
  end
end
