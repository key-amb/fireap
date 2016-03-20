require 'fireap/controller/fire'
require 'fireap/context'

require 'lib/test_config'

class TestContext
  attr :ctx
  def initialize
    config = TestConfig.tasks # will be ctx.config
    @ctx = Fireap::Context.new
  end
end

describe 'Fireap::Controller::Fire#new' do
  ctx    = TestContext.new.ctx
  config = ctx.config
  apps   = config.task['apps']
  context 'given valid arguments' do
    it 'can new' do
      firer = Fireap::Controller::Fire.new({'app' => apps.keys[0]}, ctx)
      expect(firer).to be_an_instance_of(Fireap::Controller::Fire)
    end
  end
end
