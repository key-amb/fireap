module Fireap
  VERSION    = '0.4.0'
  NAME       = 'fireap'
  EVENT_NAME = 'FIREAP:TASK'

  module Kv
    PREFIX = Fireap::NAME + '/'
  end
  class Error < StandardError
  end
end
