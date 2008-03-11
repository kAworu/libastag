#!/usr/bin/ruby

$LOAD_PATH.unshift File.join( File.dirname(__FILE__), '..', 'lib' )
$LOAD_PATH.unshift File.dirname(__FILE__)


require 'fake_violet_srv'
require 'libastag/request'
require 'libastag/response'

require 'test/unit'
require 'open-uri'



#
# Start a fake server for tests
#

t = Thread.new do
  FakeVioletSrv.start 3_000, File.join( File.dirname(__FILE__), 'testsend_log.tmp' )
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
  Libastag::Request::API_URL = LOCAL_URI


  def test_fake_server_is_up
    assert_nothing_raised do
      open(LOCAL_URI) { }
    end
  end


  def test_query_new
    assert_nothing_raised { Libastag::Request::Query.new :token => GOOD_TOKEN, :serial => GOOD_SERIAL, :event => Libastag::Request::GET_SIGNATURE }
    assert_raise(ArgumentError) { Libastag::Request::Query.new :serial => GOOD_SERIAL, :event => Libastag::Request::GET_SIGNATURE }
    assert_raise(ArgumentError) { Libastag::Request::Query.new :token => GOOD_TOKEN, :event => Libastag::Request::GET_SIGNATURE }
    assert_raise(ArgumentError) { Libastag::Request::Query.new :token => GOOD_TOKEN, :serial => GOOD_SERIAL }
  end


  def test_query_to_url
    [ Libastag::Request::GET_RABBIT_NAME,
      Libastag::Request::GET_FRIENDS_LIST,
      Libastag::Request::GET_EARS_POSITION
    ].each do |e|
      q = Libastag::Request::Query.new :event => e, :serial => GOOD_SERIAL, :token => GOOD_TOKEN
      assert_equal "#{Libastag::Request::API_URL}?sn=#{GOOD_SERIAL}&token=#{GOOD_TOKEN}&#{e.to_url}", q.to_url
    end
  end


  def test_query_to_url_with_stream
    uri = 'mouhahhaha'
    stream_event = Libastag::Request::AudioStream.new(uri)
    q = Libastag::Request::Query.new :event => stream_event, :serial => GOOD_SERIAL, :token => GOOD_TOKEN
    assert_equal "#{Libastag::Request::APISTREAM_URL}?sn=#{GOOD_SERIAL}&token=#{GOOD_TOKEN}&#{stream_event.to_url}", q.to_url
  end


  def test_xml_response
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_RABBIT_NAME, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!(:xml)
    assert_nothing_raised { REXML::Document.new(rsp) }
    assert_match %r{<rsp>.*</rsp>}im, rsp
  end


  def test_wrong_serial
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_RABBIT_NAME, :serial => BAD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::NoGoodTokenOrSerial, rsp
  end


  def test_wrong_token
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_RABBIT_NAME, :serial => GOOD_SERIAL, :token => BAD_TOKEN).send!
    assert_instance_of Libastag::Response::NoGoodTokenOrSerial, rsp
  end


  def test_GET_LINKPREVIEW
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_LINKPREVIEW, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::LinkPreview, rsp
  end

  def test_GET_FRIENDS_LIST
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_FRIENDS_LIST, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::ListFriend, rsp
  end

  def test_GET_INBOX_LIST
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_INBOX_LIST, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::ListReceivedMsg, rsp
  end

  def test_GET_TIMEZONE
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_TIMEZONE, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::Timezone, rsp
  end

  def test_GET_SIGNATURE
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_SIGNATURE, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::Signature, rsp
  end

  def test_GET_BLACKLISTED
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_BLACKLISTED, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::Blacklist, rsp
  end

  def test_GET_RABBIT_STATUS
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_RABBIT_STATUS, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::RabbitSleep, rsp
  end

  def test_GET_LANG_VOICE
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_LANG_VOICE, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::VoiceListTts, rsp
  end

  def test_GET_RABBIT_NAME
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_RABBIT_NAME, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::RabbitName, rsp
  end

  def test_GET_SELECTED_LANG
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_SELECTED_LANG, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::LangListUser, rsp
  end

  def test_GET_MESSAGE_PREVIEW
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_MESSAGE_PREVIEW, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::LinkPreview, rsp
  end

  def test_GET_EARS_POSITION
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_EARS_POSITION, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::PositionEar, rsp
  end

  def test_SET_RABBIT_ASLEEP
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::SET_RABBIT_ASLEEP, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::CommandSent, rsp
  end

  def test_SET_RABBIT_AWAKE
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::SET_RABBIT_AWAKE, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::CommandSent, rsp
  end
end
