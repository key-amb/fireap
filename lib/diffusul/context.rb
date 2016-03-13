require 'logger'

module Diffusul
  class Context
    attr :config, :log
    @node = nil # Diffusul::Node of running host
    @mode = 'production'

    def initialize(config_path: nil, develop_mode: nil)
      cfg = {}
      cfg[:path] = config_path if config_path
      @config = Diffusul::Config.new(cfg)
      @log    = logger(@config.log)
      @mode   = 'develop' if develop_mode
    end

    def die(message, level=Logger::ERROR, err=Diffusul::Error)
      @log.log(level, [message, 'at', caller(1).to_s].join(%q{ }))
      raise err, message unless self.develop_mode?
    end

    def mynode
      @node ||= Diffusul::Node.new
    end

    def develop_mode?
      if    @mode == 'develop' \
        and flg = @config.enable_debugging \
        and flg != 0 and flg.length > 0
        @log.warn '[DEVELOPMENT] Called from ' + caller(1..2).to_s
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
      @log
    end
  end
end
