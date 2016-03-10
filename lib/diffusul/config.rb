require 'toml'

module Diffusul
  class Config
    @me = nil

    def initialize(path: ENV['DIFFUSUL_CONFIG_PATH'] || 'config/diffusul.toml')
      @me ||= TOML.load_file(path)
    end

    def method_missing(method)
      unless @me.has_key?(method.to_s)
        raise "No such method: #{method}!"
      end
      return @me[method.to_s]
    end
  end
end
