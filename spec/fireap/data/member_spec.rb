require 'fireap/data/member'
require 'fireap/util/consul'

describe 'Fireap::Data::Member#to_model' do
  stash = {
    'Name' => 'localhost',
    'Addr' => '127.0.0.1',
    'Port' => 8301,
    'Status' => Fireap::Util::Consul.member_status_name2code(:alive),
  }
  data = Fireap::Data::Member.new(stash)
  member = data.to_model
  it 'member is a Fireap::Model::Member' do
    expect(member).to be_an_instance_of(Fireap::Model::Member)
  end
end
