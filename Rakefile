# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

desc "Run the JS controller tests"
task :js do
  sh "npm test"
end

task default: %i[test]
