require 'fireap/util/string'

describe 'to_snakecase - string converter' do
  {
    'ID'        => 'id',
    'Key'       => 'key',
    'camelCase' => 'camel_case',
    'FooBar'    => 'foo_bar',
    'ServiceID' => 'service_id',
  }.each_pair do |k,v|
    it "#{k} => #{v}" do
      expect(k.to_snakecase).to eq(v)
    end
  end
end
