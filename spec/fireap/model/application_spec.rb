require 'fireap/model/application'

ver2next = {
  '1' => '2',
  'v1' => 'v2',
  'v0.3.1' => 'v0.3.2',
  'p208-1' => 'p208-2',
  'foo' => 'foo-1',
}

describe 'Fireap::Model::Application' do
  ver = Fireap::Model::Application::Version.new(value: 'v1')
  sem = Fireap::Model::Application::Semaphore.new(value: '5')
  nod = Fireap::Model::Node.new('test1', '127.0.0.1')
  describe 'New' do
    it 'with all params' do
      app = Fireap::Model::Application.new('foo', version: ver, semaphore: sem, node: nod)
      expect(app.name).to        eq 'foo'
      expect(app.version).to     be ver
      expect(app.semaphore).to   be sem
      expect(app.node).to        be nod
      expect(app.update_info).to be nil
    end
    it 'with least params' do
      app = Fireap::Model::Application.new('bar')
      expect(app.name).to        eq 'bar'
      expect(app.version).to     be nil
      expect(app.semaphore).to   be nil
      expect(app.node).to        be nil
      expect(app.update_info).to be nil
    end
  end
end

describe 'Fireap::Model::Application::Version' do
  describe 'Automatically determine next version' do
    ver2next.each_pair do |pre,nxt|
      it "#{pre} => #{nxt}" do
        ver = Fireap::Model::Application::Version.new(value: pre)
        expect(ver.next_version).to eq nxt
      end
    end
  end
end
