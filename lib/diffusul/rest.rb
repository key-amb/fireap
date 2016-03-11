module Diffusul
  class Rest < Diplomat::RestClient
    @access_methods = [:get]

    def get(path, params: [])
      @raw = @conn.get do |req|
        req.url concat_url [ '/v1' + path, params ]
        req.options.timeout = 10
      end
      parse_body
    end
  end
end
