# libastag's Rakefile


require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'



Rake::RDocTask.new do |t|
  t.main = "README.txt"
  t.rdoc_files.include( "README.txt", "lib/**/*.rb")
end


Rake::TestTask.new do |t|
  t.verbose = true
  t.warning = true
end

CLEAN.include 'html', 'test/**/*.tmp'
