require 'fireap/data/kv'

require 'base64'

describe 'Transform to Model::Kv' do

  describe 'Valid Kv kv_m' do
    kv = {
      'Key'   => 'version',
      'Value' => Base64.encode64('v0.1.0'),
    }
    data = Fireap::Data::Kv.new(kv)
    kv_m = data.to_model
    it 'kv_m is a Fireap::Model::Kv' do
      expect(kv_m).to be_an_instance_of(Fireap::Model::Kv)
    end
    it 'kv_m.value is decoded' do
      expect(kv_m.value).to eq 'v0.1.0'
    end
  end

  describe 'Value is undefined' do
    kv = {
      'Key'   => 'version',
      'Value' => nil,
    }
    data = Fireap::Data::Kv.new(kv)
    kv_m = data.to_model
    it 'kv_m is a Fireap::Model::Kv' do
      expect(kv_m).to be_an_instance_of(Fireap::Model::Kv)
    end
    it 'kv_m.value is nil' do
      expect(kv_m.value).to be nil
    end
  end
end
