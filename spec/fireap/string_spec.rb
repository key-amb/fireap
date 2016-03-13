require 'diffusul/string'

describe 'to_snake - string converter' do
  {
    'ID'        => 'id',
    'Key'       => 'key',
    'camelCase' => 'camel_case',
    'FooBar'    => 'foo_bar',
  }.each_pair do |k,v|
    it "#{k} => #{v}" do
      expect(k.to_snake).to eq(v)
    end
  end
end
