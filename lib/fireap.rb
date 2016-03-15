module Fireap
  NAME = 'fireap'
  module Kv
    PREFIX = Fireap::NAME + '/'
  end
  class Error < StandardError
  end
end
