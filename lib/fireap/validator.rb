require 'data/validator'

require 'fireap'

module Fireap
  class Validator
    Error = Class.new(StandardError)

    def initialize(rules)
      @rules = rules
      @validator = ::Data::Validator.new(rules)
    end

    def validate(args)
      errors = []
      begin
        result = @validator.validate(args)
      rescue => e
        errors << e
      end
      extra = find_extra(args, @rules)
      if extra.length > 0
        errors << Error.new("#{extra.inspect} extra")
      end
      if errors.length > 0
        raise Error, errors.join("\n")
      end
      true
    end

    private

    def find_extra(given, rules, prefix='')
      extra = []
      given.each_pair do |key, val|
        if ! rules.has_key?(key)
          extra << prefix + key
        elsif rules[key].has_key?(:rule)
          extra.concat( find_extra(val, rules[key][:rule], prefix + "#{key}.") )
        end
      end
      extra
    end
  end
end
