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

  # Sweet Hack
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


  def good_query_sender(e)
    Libastag::Request::Query.new(:event => e, :serial => GOOD_SERIAL, :token => GOOD_TOKEN).send!
  end

  def test_wrong_serial
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_RABBIT_NAME, :serial => BAD_SERIAL, :token => GOOD_TOKEN).send!
    assert_instance_of Libastag::Response::NoGoodTokenOrSerial, rsp
  end


  def test_wrong_token
    rsp = Libastag::Request::Query.new(:event => Libastag::Request::GET_RABBIT_NAME, :serial => GOOD_SERIAL, :token => BAD_TOKEN).send!
    assert_instance_of Libastag::Response::NoGoodTokenOrSerial, rsp
  end


  def test_all_actions
    assert_instance_of Libastag::Response::LinkPreview,     good_query_sender(Libastag::Request::GET_LINKPREVIEW)
    assert_instance_of Libastag::Response::ListFriend,      good_query_sender(Libastag::Request::GET_FRIENDS_LIST)
    assert_instance_of Libastag::Response::ListReceivedMsg, good_query_sender(Libastag::Request::GET_INBOX_LIST)
    assert_instance_of Libastag::Response::Timezone,        good_query_sender(Libastag::Request::GET_TIMEZONE)
    assert_instance_of Libastag::Response::Signature,       good_query_sender(Libastag::Request::GET_SIGNATURE)
    assert_instance_of Libastag::Response::Blacklist,       good_query_sender(Libastag::Request::GET_BLACKLISTED)
    assert_instance_of Libastag::Response::RabbitSleep,     good_query_sender(Libastag::Request::GET_RABBIT_STATUS)
    assert_instance_of Libastag::Response::VoiceListTts,    good_query_sender(Libastag::Request::GET_LANG_VOICE)
    assert_instance_of Libastag::Response::RabbitName,      good_query_sender(Libastag::Request::GET_RABBIT_NAME)
    assert_instance_of Libastag::Response::LangListUser,    good_query_sender(Libastag::Request::GET_SELECTED_LANG)
    assert_instance_of Libastag::Response::LinkPreview,     good_query_sender(Libastag::Request::GET_MESSAGE_PREVIEW)
    assert_instance_of Libastag::Response::PositionEar,     good_query_sender(Libastag::Request::GET_EARS_POSITION)
    assert_instance_of Libastag::Response::CommandSent,     good_query_sender(Libastag::Request::SET_RABBIT_ASLEEP)
    assert_instance_of Libastag::Response::CommandSent,     good_query_sender(Libastag::Request::SET_RABBIT_AWAKE)
  end
end
