module Fireap
  VERSION    = '0.1.2'
  NAME       = 'fireap'
  EVENT_NAME = 'FIREAP:TASK'

  module Kv
    PREFIX = Fireap::NAME + '/'
  end
  class Error < StandardError
  end
end
