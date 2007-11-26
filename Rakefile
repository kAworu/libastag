# libastag's Rakefile


#
# RDoc
#
require 'rake/rdoctask'

Rake::RDocTask.new do |rd|
  rd.main        = "README.txt"
  rd.rdoc_dir    = 'doc'
  rd.title       = 'libastag.rb'
  rd.options     = %w[ --charset utf-8
                      --diagram ]
  rd.rdoc_files.include( "README.txt", "lib/**/*.rb")
end



#
# Tests
#
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.verbose = true
  t.warning = true
end



#
# Cleaning
#
require 'rake/clean'

CLOBBER.include 'doc', 'pkg'
CLEAN.include   'test/**/*.tmp'



#
# Pkg
#
require 'rake/gempackagetask'

gem_spec = Gem::Specification.new do |s|
  s.author       = "Alexandre Perrin"
  s.email        = "kaworu@kaworu.ch"
  s.homepage     = "http://libastag.kaworu.ch"

  s.name        = "libastag"
  s.summary     = "A library for sending commands to Nabastag(/tag) (see http://www.nabaztag.com)"
  s.description = <<-EOF
                  libastag is a full featured library for the Nabastag API (see http://api.nabaztag.com/docs/home.html).
                  It provide also a minimal fake Violet Server for testing purpose.
                  Main concepts are :
                  * complete Rdoc documentations
                  * Unit testing
                  * Easy to use
                  EOF

  s.test_files          = Dir["test/**/*"]
  s.extra_rdoc_files    = Dir["README.txt", "LICENSE.txt"]
  s.files               = Dir["lib/**/*", "bin/*"] + Dir["Rakefile"] + s.test_files + s.extra_rdoc_files
  s.version             = "0.0.1"
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

