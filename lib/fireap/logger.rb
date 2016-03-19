require 'logger'

module Fireap

  # Logger Factory class to controll logging
  class Logger

    # @param outs [Array] Log outputs. Given to Logger.new as logdev
    # @param rotate [Fixnum, String] shift_age param in Logger.new
    # @param level Log level defined as constants in Logger class
    def initialize(outs, rotate: 0, level: 'INFO')
      @loggers = []
      outs.each do |out|
        logger = ::Logger.new(out, rotate)
        logger.level = Object.const_get("Logger::#{level}")
        logger.formatter = proc do |level, date, prog, msg|
          "#{date} [#{level}] #{msg} -- #{prog}\n"
        end
        @loggers.push(logger)
      end
    end

    def log(level=::Logger::INFO, message)
      @loggers.each do |logger|
        logger.log(level, message, $0)
      end
    end

    # Supposed to receive logging methods like :info, :warn or others which
    # is given to Logger instances in @loggers.
    def method_missing(method, *args)
      @loggers.each do |logger|
        logger.send(method, *args)
      end
    end
  end
end
