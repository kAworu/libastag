# libastag's Rakefile
MY_PROJECT_VERSION = '0.0.1'


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
  s.homepage     = "http://libastag.rubyforge.org"

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
  s.version             = MY_PROJECT_VERSION
  #s.rubyforge_project   = "libastag" # TODO
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end



#
# stats
#
# ScriptLines class is code from Oreilly's "Ruby Cookbook" (rewritted a bit)
#
module Stats
  # A ScriptLines instance analyses a Ruby script and maintains
  # counters for the total number of lines, lines of  code, etc.
  class ScriptLines

    attr_reader :name
    attr_accessor :bytes, :lines, :lines_of_code, :lines_of_comments

    LINE_FORMAT = '%8s %8s %8s %8s    %s'


    def ScriptLines.headline
      LINE_FORMAT % %w[ BYTES LINES LOC COMMENT FILE ]
    end

    # The 'name' argument is usually a filename
    def initialize(name)
      @name = name
      @bytes, @lines, @lines_of_code, @lines_of_comments = 0, 0, 0, 0
    end

    # Iterates over all the lines in io (io might be a file or a string), analyses them and appropriately increases
    # the counter attributes.
    def read(io)
      in_multiline_comment = false

      io.each do |line|
        @lines += 1
        @bytes += line.size

        case line
        when /^=(begin|end)/  # multi line comment
          @lines_of_comments += 1
          in_multiline_comment = ($1 == 'begin')

        when /^\s*#/ # Comment line
          @lines_of_comments += 1

        when /^\s*$/ # empty/whitespace only line
          # do nothin' :)

        else
          if in_multiline_comment then @lines_of_comments += 1 else @lines_of_code += 1 end
        end
      end
    end

    # Get a new ScriptLines instance whose counters hold the
    # sum of self and other.
    def +(other)
      sum = self.dup
      sum.bytes += other.bytes
      sum.lines += other.lines
      sum.lines_of_code += other.lines_of_code
      sum.lines_of_comments += other.lines_of_comments
      sum
    end

    # Get a formatted string containing all counter numbers and the
    # name of this instance.
    def to_s
      LINE_FORMAT % [@bytes, @lines, @lines_of_code, @lines_of_comments, @name]
    end
  end

end


task 'stats' do
  include Stats

  files = Dir["lib/**/*.rb"]

  puts ScriptLines.headline
  sum = ScriptLines.new("TOTAL (#{files.size} file(s))")

  files.each do |f|
    sl = ScriptLines.new f
    sl.read File.read(f)
    puts sl
    sum += sl
  end

  puts
  puts sum
end
