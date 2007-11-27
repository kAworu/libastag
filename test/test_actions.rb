#!/usr/bin/ruby


require File.join( File.dirname(__FILE__), 'fake_violet_srv.rb')
require File.join( File.dirname(__FILE__), '..', 'lib', 'violet', 'request.rb' )
require File.join( File.dirname(__FILE__), '..', 'lib', 'violet', 'response.rb' )

require 'test/unit'
require 'open-uri'



# Start a fake server for tests
t = Thread.new do
  FakeVioletSrv.start 3000, 'testactions_log.tmp'
end
sleep 1 # wait for server start.


class ActionTest < Test::Unit::TestCase

  def test_fake_server
    assert_nothing_raised do
      open("http://localhost:3000/api.jsp?") { }
    end
  end

  def test_xml_response
  end

  def test_wrong_serial
    rsp = Request::Query.send!(Request::GET_EARS_POSITION, 'wrong serial', '0987654321')
    assert_instance_of Response::Wrapper
  end

  def test_wrong_token
  end
end
