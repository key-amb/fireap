require 'base64'

module Diffusul
  module Watch
    def self.handle(events: nil, config: nil)
      events.each do |ev|
        ev.each_pair do |key, val|
          if key == 'Payload'
            disp_val = JSON.parse( Base64.decode64(val) )
          end
          disp_val ||= val
          p({'key' => key, 'value' => disp_val})
        end
      end
    end
  end
end
