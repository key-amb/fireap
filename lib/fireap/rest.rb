module Fireap
  class Rest < Diplomat::RestClient
    @access_methods = [:get]

    def get(path, params: [])
      begin
        @raw = @conn.get do |req|
          req.url concat_url [ '/v1' + path, params ]
          req.options.timeout = 10
        end
      rescue => e
        logger = Fireap::Context.new.log
        logger.info "REST failed. Data not found. path=#{path}"
        logger.debug e
        return nil
      end
      parse_body
    end
  end
end
