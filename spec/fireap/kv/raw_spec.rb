require 'fireap/kv/raw'

require 'base64'

kv = {
  'Key'   => 'version',
  'Value' => Base64.encode64('v0.1.0'),
}

raw  = Fireap::Kv::Raw.new(kv)
data = raw.to_data

describe 'New Kv raw/data' do
  it 'data is a Fireap::Kv::Data' do
    expect(data).to be_an_instance_of(Fireap::Kv::Data)
  end
  it 'data.value is decoded' do
    expect(data.value).to eq 'v0.1.0'
  end
end
