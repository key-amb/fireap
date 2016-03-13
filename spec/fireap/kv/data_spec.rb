require 'diffusul/kv/data'

kv1 = Diffusul::Kv::Data.new(
  key: 'version',
  value: 'v0.1',
  modify_index: '1',
  is_dirty: false,
)
kv2 = kv1.clone

describe 'Update Kv data' do
  describe 'Case - Diplomat::Kv#put succeeds' do
    before do
      allow(Diplomat::Kv).to receive_message_chain(:put).and_return(true)
    end
    it 'update succeeds' do
      ret = kv1.update('v0.2')
      expect(ret).to be true
      expect(kv1.value).to eq 'v0.2'
      expect(kv1.is_dirty).to be true
    end
  end

  describe 'Case - Diplomat::Kv#put fails' do
    before do
      allow(Diplomat::Kv).to receive_message_chain(:put).and_return(false)
    end
    it 'update fails' do
      ret = kv2.update('v0.2')
      expect(ret).to be false
      expect(kv2.value).to eq 'v0.1'
      expect(kv2.is_dirty).to be false
    end
  end
end
