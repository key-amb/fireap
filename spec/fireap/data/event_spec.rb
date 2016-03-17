require 'fireap'
require 'fireap/data/event'

require 'base64'
require 'json'

payload = {'name' => 'foo', 'version' => 'v1'}

describe 'Transform to Model::Event' do

  describe 'Valid Event data' do
    evt = {
      'ID'   => '5bce61f8-eaad-ff09-b5a3-89818cdb6b7b',
      'Name' => Fireap::EVENT_NAME,
      'Payload' => Base64.encode64(payload.to_json),
    }
    data  = Fireap::Data::Event.new(evt)
    event = data.to_model
    it 'event is a Fireap::Model::Event' do
      expect(event).to be_an_instance_of(Fireap::Model::Event)
    end
    it 'event.payload is decoded' do
      expect(event.payload).to eq payload
    end
  end

  describe 'Valid Event data' do
    evt = {
      'ID'   => '5bce61f8-eaad-ff09-b5a3-89818cdb6b7b',
      'Name' => Fireap::EVENT_NAME,
      'Payload' => nil,
    }
    data  = Fireap::Data::Event.new(evt)
    event = data.to_model
    it 'event is a Fireap::Model::Event' do
      expect(event).to be_an_instance_of(Fireap::Model::Event)
    end
    it 'event.payload is undefined' do
      expect(event.payload).to be nil
    end
  end
end
