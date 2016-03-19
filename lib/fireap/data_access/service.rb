require 'diplomat'

require 'fireap'

module Fireap::DataAccess
  class Service
    class << self
      def catalog_all
        Diplomat::Service.get_all
      end
    end
  end
end
