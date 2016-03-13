require 'diffusul/version'

ver2next = {
  '1' => '2',
  'v1' => 'v2',
  'v0.3.1' => 'v0.3.2',
  'p208-1' => 'p208-2',
  'foo' => 'foo-1',
}

describe 'Automatically determine next version' do
  ver2next.each_pair do |pre,nxt|
    it "#{pre} => #{nxt}" do
      ver = Diffusul::Version.new(value: pre)
      expect(ver.next_version).to eq nxt
    end
  end
end
