#!/usr/bin/ruby


def from_this_file_path *args
  File.join( File.dirname(__FILE__), *args )
end


require from_this_file_path('fake_violet_srv.rb')
require from_this_file_path('..', 'lib', 'violet', 'request',  'request.rb' )
require from_this_file_path('..', 'lib', 'violet', 'response', 'response.rb')

require 'test/unit'
require 'open-uri'



#
# Start a fake server for tests
#

t = Thread.new do
  FakeVioletSrv.start 3000, from_this_file_path('testsend_log.tmp')
end
sleep 1 # wait for server start.


class QueryAndActionTest < Test::Unit::TestCase
  require 'rexml/document'

  GOOD_SERIAL   = '1234567890AB'
  GOOD_TOKEN    = '1234567890'
  BAD_SERIAL    = '1X34U67890AB'
  BAD_TOKEN     = '123456789A'

  LOCAL_URI     = 'http://localhost:3000/api.jsp'

  # Hacky ! yes !
  Request::API_URL = LOCAL_URI


  def test_fake_server_is_up
    assert_nothing_raised do
      open(LOCAL_URI) { }
    end
  end


  def test_query_new
    assert_nothing_raised { Request::Query.new :token => GOOD_TOKEN, :serial => GOOD_SERIAL, :event => Request::GET_SIGNATURE }
    assert_raise(ArgumentError) { Request::Query.new :serial => GOOD_SERIAL, :event => Request::GET_SIGNATURE }
    assert_raise(ArgumentError) { Request::Query.new :token => GOOD_TOKEN, :event => Request::GET_SIGNATURE }
    assert_raise(ArgumentError) { Request::Query.new :token => GOOD_TOKEN, :serial => GOOD_SERIAL }
  end


  def test_query_to_url
    [ Request::GET_RABBIT_NAME,
      Request::GET_FRIENDS_LIST,
      Request::GET_EARS_POSITION
    ].each do |e|
      q = Request::Query.new :event => e, :serial => GOOD_SERIAL, :token => GOOD_TOKEN
      assert_equal "#{Request::API_URL}?sn=#{GOOD_SERIAL}&token=#{GOOD_TOKEN}&#{e.to_url}", q.to_url
    end
  end


  def test_xml_response
    rsp = Request::Query.new(:event => Request::GET_RABBIT_NAME, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!(:xml)
    assert_nothing_raised { REXML::Document.new(rsp) }
    assert_match %r{<rsp>.*</rsp>}im, rsp
  end


  def test_wrong_serial
    rsp = Request::Query.new(:event => Request::GET_RABBIT_NAME, :serial => BAD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::NoGoodTokenOrSerial, rsp
  end


  def test_wrong_token
    rsp = Request::Query.new(:event => Request::GET_RABBIT_NAME, :serial => GOOD_SERIAL, :token => BAD_TOKEN).send!
    assert_instance_of Response::NoGoodTokenOrSerial, rsp
  end


  def test_GET_LINKPREVIEW
    rsp = Request::Query.new(:event => Request::GET_LINKPREVIEW, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::LinkPreview, rsp
  end

  def test_GET_FRIENDS_LIST
    rsp = Request::Query.new(:event => Request::GET_FRIENDS_LIST, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::ListFriend, rsp
  end

  def test_GET_INBOX_LIST
    rsp = Request::Query.new(:event => Request::GET_INBOX_LIST, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::ListReceivedMsg, rsp
  end

  def test_GET_TIMEZONE
    rsp = Request::Query.new(:event => Request::GET_TIMEZONE, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::Timezone, rsp
  end

  def test_GET_SIGNATURE
    rsp = Request::Query.new(:event => Request::GET_SIGNATURE, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::Signature, rsp
  end

  def test_GET_BLACKLISTED
    rsp = Request::Query.new(:event => Request::GET_BLACKLISTED, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::Blacklist, rsp
  end

  def test_GET_RABBIT_STATUS
    rsp = Request::Query.new(:event => Request::GET_RABBIT_STATUS, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::RabbitSleep, rsp
  end

  def test_GET_LANG_VOICE
    rsp = Request::Query.new(:event => Request::GET_LANG_VOICE, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::VoiceListTts, rsp
  end

  def test_GET_RABBIT_NAME
    rsp = Request::Query.new(:event => Request::GET_RABBIT_NAME, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::RabbitName, rsp
  end

  def test_GET_SELECTED_LANG
    rsp = Request::Query.new(:event => Request::GET_SELECTED_LANG, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::LangListUser, rsp
  end

  def test_GET_MESSAGE_PREVIEW
    rsp = Request::Query.new(:event => Request::GET_MESSAGE_PREVIEW, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::LinkPreview, rsp
  end

  def test_GET_EARS_POSITION
    rsp = Request::Query.new(:event => Request::GET_EARS_POSITION, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::PositionEar, rsp
  end

  def test_SET_RABBIT_ASLEEP
    rsp = Request::Query.new(:event => Request::SET_RABBIT_ASLEEP, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::CommandSend, rsp
  end

  def test_SET_RABBIT_AWAKE
    rsp = Request::Query.new(:event => Request::SET_RABBIT_AWAKE, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Response::CommandSend, rsp
  end
end
