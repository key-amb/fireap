require 'diffusul/kv/raw'

require 'base64'

kv = {
  'Key'   => 'version',
  'Value' => Base64.encode64('v0.1.0'),
}

raw  = Diffusul::Kv::Raw.new(kv)
data = raw.to_data

describe 'New Kv raw/data' do
  it 'data is a Diffusul::Kv::Data' do
    expect(data).to be_an_instance_of(Diffusul::Kv::Data)
  end
  it 'data.value is decoded' do
    expect(data.value).to eq 'v0.1.0'
  end
end
