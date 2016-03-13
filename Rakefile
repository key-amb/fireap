task :default => :test

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:test) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end
