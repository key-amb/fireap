require 'fireap'
require 'fireap/data/node'

describe 'Fireap::Data::Node#to_model' do
  stash = {
    'Node'      => 'test1',
    'Address'   => '192.168.100.1',
    'ServiceID' => 'web',
  }

  data = Fireap::Data::Node.new(stash)
  node = data.to_model
  it 'node is a Fireap::Model::Node' do
    expect(node).to be_an_instance_of(Fireap::Model::Node)
  end
  describe 'all params set as instance_variable' do
    { 'name' => 'Node', 'address' => 'Address' }.each_pair do |key, orig_key|
      it "#{key} => #{stash[orig_key]}" do
        expect( node.send(key) ).to eq stash[orig_key]
      end
    end
    it "service_id => #{stash['ServiceID']}" do
      expect( node.instance_variable_get("@service_id") ).to eq stash['ServiceID']
    end
  end
end
