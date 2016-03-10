require 'ostruct'
require 'optparse'

require 'diffusul/deploy'
require 'diffusul/watch'

module Diffusul
  @@commands = %w(deploy watch)

  def self.run(args)
    cmd = args.shift or raise 'Not specified command!'
    unless @@commands.include?(cmd)
      raise "Unknown command! #{cmd}"
    end
    case cmd
    when 'deploy'
      key    = args.shift or raise 'Not specified deploy key!'
      option = OpenStruct.new({ 'key' => key })
      oparse = OptionParser.new
      oparse.on('-v', '--version=VERSION') { |v| option.version = v }
      oparse.parse!(args)
      Deploy.start(option)
    when 'watch'
      data = ''
      while ins = $stdin.gets
        data << ins
      end
      Watch.handle(data: data)
    end
  end
end
