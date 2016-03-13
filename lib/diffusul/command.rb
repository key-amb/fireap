require 'erb'
require 'open3'

module Diffusul
  class Command
    attr :format, :app, :remote, :config, :ctx

    def initialize(args)
      args.each do |key, val|
        instance_variable_set("@#{key}", val)
      end
    end

    def run
      @script = ERB.new(@format).result(binding)
      prefix  = @ctx.dry_run? ? '' : 'EXEC '
      @ctx.log.info "#{prefix}#{@script}"
      if ! @ctx.dry_run?
        @result = Result.new(@script, Open3.capture3(@script) )
        if @result.is_failed?
          @ctx.log.error %Q|Command FAILED! #{@result.to_s}|
        else
          @ctx.log.info %Q|Command Succeeded. #{@result.to_s}|
        end
      else
        @result = Result.fake(@script, success: true)
        @ctx.log.debug %Q|Assume Success. #{@result.to_s}|
      end
      @result
    end

    class Result
      attr :command, :stdout, :stderr, :status, :exit

      def initialize(command, captured)
        @command = command
        @stdout, @stderr, @status = captured
        @exit = @status.exitstatus
      end

      def self.fake(command, success: true)
        status = OpenStruct.new({
          pid:        '<#dummy>',
          exitstatus: success ? 0 : 1,
        })
        new(command, ['<stdout>', '<stderr>', status])
      end

      def to_s
        %q|EXIT=%d, PID = %s, STDOUT = [%s], STDERR = [%s]|%[
          @exit, @status.pid, @stdout.chomp, @stderr.chomp
        ]
      end

      def is_failed?
        @exit != 0
      end

      def is_ignored?
        @ignored
      end

      def mark_ignored
        @ignored = true
      end

    end
  end
end
