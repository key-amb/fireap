require 'fireap/model/member'
require 'fireap/util/string'

require 'diplomat'

describe 'Fireap::Model::Member#select' do
  context 'when API call fails' do
    before(:example) do
      allow(Diplomat::Members).to receive(:get).and_return(nil)
    end
    it 'return nil' do
      expect(Fireap::Model::Member.select).to be nil
    end
  end

  context 'when API respond valid data' do
    statuses = [:alive, :failing]
    # @node some of tests below assume :alive member number is 1
    list = [
      {
        'Name' => 'test1',
        'Addr' => '192.68.100.1',
        'Port' => 8301,
        'Status' => Fireap::Util::Consul.member_status_name2code(statuses[0]),
      },
      {
        'Name' => 'test2',
        'Addr' => '192.68.100.2',
        'Port' => 8301,
        'Status' => Fireap::Util::Consul.member_status_name2code(statuses[1]),
      },
    ]

    before(:example) do
      allow(Diplomat::Members).to receive(:get).and_return(list)
    end
    context 'when get all as array' do
      before(:example) do
        @members = Fireap::Model::Member.select
      end
      it 'member number is same to list length' do
        expect(@members.size).to eq list.length
      end
      describe 'all parameters should match data' do
        before(:example) do
          allow(Diplomat::Members).to receive(:get).and_return(list)
        end
        list.each_with_index do |data, idx|
          data.each_pair do |key, val|
            method = key.to_snakecase
            it "##{method} => #{val}" do
              expect( @members[idx].send(method) ).to eq val
            end
          end
          it "#status_name => :#{statuses[idx]}" do
            expect(@members[idx].status_name).to eq statuses[idx]
          end
        end
      end
    end

    context 'when get :alive as hash' do
      before(:example) do
        @members = Fireap::Model::Member.select(status: :alive, as: :hash)
      end
      describe 'only :alive member is found' do
        alive_data = list.select do |d|
          d['Status'] == Fireap::Util::Consul.member_status_name2code(:alive)
        end
        it 'retval is a Hash' do
          expect(@members.class).to be Hash
        end
        it 'member number matches' do
          expect(@members.size).to eq alive_data.length
        end
        alive_data[0].each_pair do |key, val|
          method = key.to_snakecase
          it "##{method} => #{val}" do
            expect( @members.values[0].send(method) ).to eq val
          end
        end
      end
    end
  end
end
