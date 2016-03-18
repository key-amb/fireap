require 'fireap/util/validator'

require 'data/validator'

include Fireap::Util::Validator

describe 'Fireap::Util::Validator::BOOL_FAMILY' do
  before(:example) do
    @rule = Data::Validator.new(bool: { isa: BOOL_FAMILY })
  end
  [
    [ true, :is ], [ false, :is ], [ nil, :is ], [ 0, :is_not ]
  ].each do |sbj|
    it "#{sbj[0].to_s} #{sbj[1]} boolean" do
      case sbj[1]
      when :is
        expect( @rule.validate(bool: sbj[0]) ).to be_truthy
      when :is_not
        expect { @rule.validate(bool: sbj[0]) }.to raise_error(Data::Validator::Error)
      else
        raise "Unknown test case! #{sbj.inspect}"
      end
    end
  end

end
