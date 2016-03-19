require 'logger'

module Fireap

  # Logger Factory class to controll logging
  class Logger

    # @param outs [Array] Log outputs. Given to Logger.new as logdev
    # @param rotate [Fixnum, String] shift_age param in Logger.new
    # @param level Log level defined as constants in Logger class
    # @param header [String] Custom header for each log line
    def initialize(outs, rotate: 0, level: 'INFO', header: '')
      @loggers = []
      @header  = header.length > 0 ? header : nil
      outs.each do |out|
        logger           = ::Logger.new(out, rotate)
        logger.level     = Object.const_get("Logger::#{level}")
        logger.progname  = [$0, ARGV].join(%q[ ])
        logger.formatter = proc do |level, date, prog, msg|
          "#{date} [#{level}] #{msg} -- #{prog}\n"
        end
        @loggers.push(logger)
      end
    end

    def log(level=::Logger::INFO, message)
      @loggers.each do |logger|
        logger.log(level, custom_message(message))
      end
    end

    # Supposed to receive logging methods like :info, :warn or others which
    # is given to Logger instances in @loggers.
    def method_missing(method, *args)
      @loggers.each do |logger|
        msg = custom_message(args[0])
        new_args = args[1 .. args.size-1]
        logger.send(method, msg, *new_args)
      end
    end

    private

    def custom_message(message)
      customized = [message, 'at', caller(4, 1).to_s].join(%q[ ])
      @header ? "#{@header} #{customized}" : customized
    end
  end
end
