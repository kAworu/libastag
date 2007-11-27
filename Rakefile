# libastag's Rakefile


#
# RDoc
#
require 'rake/rdoctask'

Rake::RDocTask.new do |rd|
  rd.main        = "README"
  rd.rdoc_dir    = 'doc'
  rd.title       = 'libastag.rb'
  rd.options     = %w[ --charset utf-8
                      --diagram
                      --line-number
                      --inline-source
                      ]
  rd.rdoc_files.include( "README", "MIT-LICENSE", "TODO", "CHANGES", "lib/**/*.rb")
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
  s.homepage     = "http://libastag.kaworu.ch" # TODO @rubyforge

  s.name        = "libastag"
  s.summary     = "A library for sending commands to Nabastag(/tag) (see http://www.nabaztag.com)"
  s.description = <<-EOF
                  libastag is a full featured library for the Nabastag API (see http://api.nabaztag.com/docs/home.html).
                  It provide also a minimal fake Violet HTTP Server written with WEBrick for testing purpose.
                  Main goals are :
                  - complete Rdoc documentations
                  - Unit testing
                  - Easy to use
                  EOF

  s.has_rdoc            = true
  s.rdoc_options        = %w[ --charset utf-8 --diagram --line-number --inline-source ]
  s.extra_rdoc_files    = Dir["README", "MIT-LICENSE", "TODO", "CHANGES", "doc/**/*"]

  s.test_files          = Dir["test/**/*"]
  s.files               = Dir["lib/**/*", "bin/*", "Rakefile"] + s.test_files + s.extra_rdoc_files
  s.version             = "0.0.1"
  #s.rubyforge_project   = "libastag" # TODO
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

