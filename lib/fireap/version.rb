require 'fireap/model/kv'

module Fireap
  class Version < Fireap::Model::Kv
    def initialize(params)
      super(params)
      @value ||= '0'
    end

    def next_version
      if %r{(.*\D)?(\d+)(\D*)?}.match(@value.to_s)
        [$1, $2.to_i + 1, $3].join
      else
        @value + '-1'
      end
    end
  end
end
