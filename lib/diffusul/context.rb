require 'logger'

module Diffusul
  # Singleton class
  class Context
    attr :config, :log
    @@self = nil
    @@node = nil # Diffusul::Node of running host

    def self.get(options={})
      @@self ||= new(options)
    end

    def die(message, level=Logger::ERROR, err=Diffusul::Error)
      @log.log(level, [message, 'at', caller(1).to_s].join(%q{ }))
      raise err, message
    end

    def mynode
      @@node ||= Diffusul::Node.new
    end

    private

    def initialize(options={})
      cfg = {}
      cfg[:path] = options['config_path'] if options['config_path']
      @config = Diffusul::Config.new(cfg)
      @log    = logger(@config.log)
    end

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
