require 'fireap/model/node'
require 'fireap/util/string'

require 'diplomat'

describe 'Fireap::Model::Node#find' do
  n_hash = {
    'Node'    => 'test1',
    'Address' => '192.168.100.1',
  }
  data = {
    'Node' => n_hash,
    'Services' => {},
  }

  context 'when data is found' do
    before(:example) do
      allow(Diplomat::Node).to receive_message_chain(:get).and_return(data)
      @node = Fireap::Model::Node.find('test1')
    end
    it 'is a Fireap::Model::Node' do
      expect(@node).to be_an_instance_of(Fireap::Model::Node)
    end
    describe 'parameter matches' do
      n_hash.each_pair do |k, v|
        method = (k == 'Node') ? 'name' : k.to_snakecase
        it "#{method} => #{v}" do
          expect(@node.send(method)).to eq v
        end
      end
    end
  end
end
