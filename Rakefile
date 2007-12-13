#
# libastag's Rakefile
#

require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'



task :default => [:stats]


# perso infos
MY_NAME         = "Alexandre Perrin"
MY_EMAIL        = "makoto.kaworu@gmail.com"


# Project infos
PROJECT         = "libastag"
PROJECT_SUMMARY = "A library for sending commands to Nabastag(/tag) (see http://www.nabaztag.com)"
PROJECT_DESC    = <<-EOF
                  libastag is a full featured library for the Nabastag API (see http://api.nabaztag.com/docs/home.html).
                  It provide also a minimal fake Violet HTTP Server written with WEBrick for testing purpose.
                  Main goals are :
                  - complete Rdoc documentations
                  - Unit testing
                  - Easy to use
                  EOF

require File.join( File.dirname(__FILE__), 'lib', "#{PROJECT}.rb" )
PROJECT_VERSION = eval "#{PROJECT.capitalize}::VERSION"


# rubyforge infos
RUBYFORGE_USER  = "kaworu"
UNIX_NAME       = "libastag"


# Rdoc
RDOC_DIR        = "doc"
RDOC_OPTIONS    = [
                  "--title",        "#{PROJECT} API documentation",
                  "--main",         "README",
                  "--charset",      "utf-8",
                  "--diagram",
                  "--line-number",
                  "--inline-source"
                  ]


# files
LIB_FILES       = Dir["lib/**/*.rb"]
TEST_FILES      = Dir["test/**/*.rb"]

RDOC_FILES      = %w[ README MIT-LICENSE TODO CHANGES BUGS] + LIB_FILES
DIST_FILES      = %w[ Rakefile ] + LIB_FILES + TEST_FILES + RDOC_FILES



#
# RDoc
#
Rake::RDocTask.new do |rd|
  rd.main        = RDOC_FILES.first
  rd.rdoc_dir    = RDOC_DIR
  rd.options     = RDOC_OPTIONS
  rd.rdoc_files.include(*RDOC_FILES)
end



#
# Tests
#
Rake::TestTask.new do |t|
  t.verbose = true
  t.warning = true
end



#
# Cleaning
#
CLOBBER.include 'doc', 'pkg'
CLEAN.include   'doc', 'pkg', 'test/**/*.tmp'



#
# Pkg
#
gem_spec = Gem::Specification.new do |s|
  s.author       = MY_NAME
  s.email        = MY_EMAIL
  s.homepage     = "http://#{UNIX_NAME}.rubyforge.org"

  s.name        = PROJECT
  s.summary     = PROJECT_SUMMARY
  s.description = PROJECT_DESC

  s.has_rdoc            = true
  s.rdoc_options        = RDOC_OPTIONS
  s.extra_rdoc_files    = RDOC_FILES + Dir["#{RDOC_DIR}/**/*"]

  s.test_files          = TEST_FILES
  s.files               = DIST_FILES
  s.version             = PROJECT_VERSION
  s.rubyforge_project   = UNIX_NAME
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


desc "display somes stats (# of lines, # lines of comment/code etc.) of this project"
task 'stats' do

  def stats_display name, files
    include Stats
    puts "\nStats (#{name})"
    puts ScriptLines.headline
    sum = ScriptLines.new("TOTAL (#{files.size} file(s))")

    files.each do |f|
      sl = ScriptLines.new f
      sl.read File.read(f)
      puts sl
      sum += sl
    end
    puts sum
    sum
  end

  libstats  =   stats_display 'lib files',  LIB_FILES
  teststats =   stats_display 'test files', TEST_FILES

  puts
  puts "Ratio (test    / code) = %.2f" % (teststats.lines_of_code.to_f / libstats.lines_of_code)
  puts "Ratio (comment / code) = %.2f" % (libstats.lines_of_comments.to_f / libstats.lines_of_code)
end



#
# publish
#
desc "setup for RubyForge"
task "rubyforge-setup" do
  unless File.exist?( File.join(ENV['HOME'], '.rubyforge') )
    puts <<-EOF
    rubyforge will ask you to edit its config file now.
    Please set the 'username' and 'password' entries to your RubyForge username/password !
    press ENTER to continue.
    EOF
    STDIN.gets
    sh "rubyforge setup", :verbose => true
  end
end

desc "Connection to RubyForge's server"
task "rubyforge-login" => %w[ rubyforge-setup ] do
  sh "rubyforge login", :verbose => true
end


desc "Upload documentation to RubyForge"
task "publish-doc" => %w[ rdoc ] do
  rubyforge_path = "/var/www/gforge-projects/#{UNIX_NAME}/"
  sh "scp -r #{RDOC_DIR}/* '#{RUBYFORGE_USER}@rubyforge.org:#{rubyforge_path}'", :verbose => true
end

desc "Upload package to RubyForge"
task "publish-packages" => %w[ package rubyforge-login ] do
  cd "pkg" do
    %w[ gem tgz zip ].each do |pkgtype|
      sh "rubyforge add_release #{UNIX_NAME} #{UNIX_NAME} #{PROJECT_VERSION} #{UNIX_NAME}-#{PROJECT_VERSION}.#{pkgtype}"
    end
  end
end

desc  "Run tests, generate RDoc and create packages."
task "pre-release" => %w[ clobber clean ] do
  puts "Preparing release of #{PROJECT} v#{PROJECT_VERSION}"
  Rake::Task["test"].invoke
  Rake::Task["rdoc"].invoke
  Rake::Task["package"].invoke
end

desc "Publish a new release of #{PROJECT}"
task "publish" => %w[ pre-release ] do
  puts "Uploading doc..."
  Rake::Task["publish-doc"].invoke
  puts "Uploading packages..."
  Rake::Task["publish-packages"].invoke
  puts "release done !"
end

