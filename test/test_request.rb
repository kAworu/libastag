#!/usr/bin/ruby


def from_this_file_path *args
  File.join( File.dirname(__FILE__), *args )
end


require from_this_file_path('..', 'lib', 'violet', 'request',  'request.rb' )
require from_this_file_path('..', 'lib', 'violet', 'response', 'response.rb')

require 'test/unit'



class RequestTest < Test::Unit::TestCase
  def test_dummy_test
    # still todo :)
  end
end
