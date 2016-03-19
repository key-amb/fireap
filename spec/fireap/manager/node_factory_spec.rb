require 'fireap/manager/node_factory'

require 'diplomat'

include Fireap::Manager

describe 'Fireap::Manager::NodeFactory#catalog_service' do
  data = [
    {
      'Name'      => 'test1',
      'Address'   => '192.168.101.1',
      'ServiceID' => 'web',
    },
    {
      'Name'      => 'test2',
      'Address'   => '192.168.101.2',
      'ServiceID' => 'web',
    },
  ]

  context 'when Diplomat::Service#get return Node data' do
    before(:example) do
      allow(Diplomat::Service).to receive_message_chain(:get).and_return(data)
    end
    it 'returned data number matches' do
      nodes = NodeFactory.catalog_service('web')
      expect(nodes.size).to eq data.size
    end
  end
end

describe 'Fireap::Manager::NodeFactory#catalog_service_by_filter' do
  catalog = {
    'foo' => %w(v1 v2),
    'bar' => [],
  }
  data = [{
    'Name'      => 'test1',
    'Address'   => '192.168.101.1',
    'ServiceID' => 'web',
  }]
  context "Service Catalog: #{catalog.inspect}" do
    before do
      allow(Diplomat::Service).to receive_message_chain(:get).and_return(data)
      allow(Diplomat::Service).to receive_message_chain(:get_all).and_return(catalog)
    end

    context 'with service_filter: ^(foo|bar)$, tag_filter: nil' do
      it 'matches 3 times' do
        nodes = NodeFactory.catalog_service_by_filter('^(foo|bar)$')
        expect(nodes.size).to eq 3
      end
    end
    context 'with service_filter: ^(foo|bar).*$, tag_filter: ^v[12]$' do
      it 'matches 2 times' do
        nodes = NodeFactory.catalog_service_by_filter('^(foo|bar).*$', tag_filter: '^v[12]$')
        expect(nodes.size).to eq 2
      end
    end
    context 'with service_filter: ^bar, tag_filter: v3' do
      it 'matches 0 times' do
        nodes = NodeFactory.catalog_service_by_filter('^bar', tag_filter: 'v3')
        expect(nodes.size).to eq 0
      end
    end
  end
end
