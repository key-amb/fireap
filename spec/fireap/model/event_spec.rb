require 'fireap'
require 'fireap/data/event'

require 'base64'
require 'json'
require 'tempfile'

def test_event_data_match(event, data)
  describe "Test event data match. ID=#{event.id}" do
    it 'event is a Fireap::Model::Event' do
      expect(event).to be_an_instance_of(Fireap::Model::Event)
    end
    it 'check id/payload match' do
      expect(event.id).to eq data['ID']
      expect(event.payload).to eq JSON.parse( Base64.decode64(data['Payload']) )
    end
    it 'name is set default when data is undefined' do
      if data['Name']
        expect(event.name).to eq data['Name']
      else
        expect(event.name).to eq Fireap::EVENT_NAME
      end
    end
  end
end

describe 'Fireap::Model::Event' do
  payloads = [
    {'name' => 'foo', 'version' => 'v1'},
    {'name' => 'bar', 'version' => 'v2'},
  ]

  data = [
    {
      'ID'   => '5bce61f8-eaad-ff09-b5a3-89818cdb6baa',
      'Name' => 'test-event',
      'Payload' => Base64.encode64(payloads[0].to_json),
    },
    {
      'ID'   => '1bce61f8-eaad-ff09-b5a3-89818cdb6aaa',
      'Payload' => Base64.encode64(payloads[1].to_json),
    }
  ]

  describe 'Class method "convert_from_streams"' do
    describe 'returns all parsed event objects' do
      events = Fireap::Model::Event.convert_from_streams(data.to_json)
      it 'all given data are parsed' do
        expect(data.size).to eq events.size
      end
      events.each_with_index do |event, i|
        test_event_data_match(event, data[i])
      end
    end
  end

  describe 'Class method "fetch_from_stdin"' do
    describe 'case no input' do
      $stdin = StringIO.new(data.to_json)
      it 'return nothing' do
      end
    end

    describe 'case data are set' do
      $stdin = StringIO.new(data.to_json)

      event = Fireap::Model::Event.fetch_from_stdin
      describe 'returns last event' do
        test_event_data_match(event, data[1])
      end
    end
  end
end
