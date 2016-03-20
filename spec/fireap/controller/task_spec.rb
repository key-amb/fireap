require 'fireap/controller/task'
require 'fireap/context'

require 'lib/test_config'

class TestContext
  attr :ctx
  def initialize
    config = TestConfig.tasks # will be ctx.config
    @ctx = Fireap::Context.new
  end
end

describe 'Fireap::Controller::Task#show' do
  ctx    = TestContext.new.ctx
  config = ctx.config
  apps   = config.task['apps']
  context 'when config is valid' do
    it 'print output' do
      $stdout = StringIO.new
      Fireap::Controller::Task.new.show({'width' => 80}, ctx)
      output  = $stdout.string
      expect(output.length > 0).to be true
      $stdout = STDOUT
    end
  end
end
