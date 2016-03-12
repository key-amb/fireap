require 'logger'

module Diffusul
  class Context
    attr :config, :log
    @@me = nil

    def initialize(options={})
      cfg = {}
      cfg[:path] = options['config_path'] if options['config_path']
      @config = Diffusul::Config.new(cfg)
      @log    = logger(@config.log)
    end

    def self.get(options={})
      @@me ||= new(options)
    end

    def die(message, level=Logger::ERROR, err=Diffusul::Error)
      @log.log(level, [message, 'at', caller(1).to_s].join(%q{ }))
      raise err, message
    end

    private

    def logger(config)
      dest   = config['file'] || STDOUT
      rotate = config['rotate'] || 0
      level  = config['level'] || 'INFO'
      @log   = Logger.new(dest, rotate)
      @log.level = Object.const_get("Logger::#{level}")
      @log
    end
  end
end
