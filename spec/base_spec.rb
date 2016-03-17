require 'rspec'

describe 'Require All *.rb files' do
  Dir[ File.join(File.dirname(__FILE__), '..', 'lib', '**/*.rb') ].each do |f|
    it "require #{f}" do
      ret = require f
      expect(ret).to_not be_nil
    end
  end
end
