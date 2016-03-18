require 'fireap/util/consul'

include Fireap::Util

describe 'member_status_name2code' do
  {
    alive: 1,
    'no-such-name' => -1
  }.each_pair do |key, val|
    it "#{key} => #{val}" do
      expect( Consul.member_status_name2code(key) ).to eq val
    end
  end
end

describe 'member_status_code2name' do
  {
    '1'   => :alive,
    '-99' => :__unknown__,
  }.each_pair do |key, val|
    it "#{key} => :#{val}" do
      expect( Consul.member_status_code2name(key.to_i) ).to eq val
    end
  end
end
