#!/usr/bin/ruby


def from_this_file_path *args
  File.join( File.dirname(__FILE__), *args )
end


require from_this_file_path('fake_violet_srv.rb')
require from_this_file_path('..', 'lib', 'violet', 'request.rb')
require from_this_file_path('..', 'lib', 'violet', 'response.rb')

require 'test/unit'
require 'open-uri'



#
# Start a fake server for tests
#

t = Thread.new do
  FakeVioletSrv.start 3000, from_this_file_path('testactions_log.tmp')
end
sleep 1 # wait for server start.


class ActionTest < Test::Unit::TestCase

  GOOD_SERIAL   = '1234567890AB'
  GOOD_TOKEN    = '1234567890'
  BAD_SERIAL    = '1X34U67890AB'
  BAD_TOKEN     = '123456789A'

  LOCAL_URI     = "http://localhost:3000/api.jsp?"

  # Hacky ! yes !
  Request::API_URL = LOCAL_URI


  def test_fake_server_is_up
    assert_nothing_raised do
      open(LOCAL_URI) { }
    end
  end


  def test_xml_response
    rsp = Request::Query.new(Request::GET_RABBIT_NAME, GOOD_SERIAL, GOOD_TOKEN).send!(:xml)
    assert_nothing_raised do
      require 'rexml/document'
      REXML::Document.new(rsp)
    end
  end


  def test_wrong_serial
    rsp = Request::Query.new(Request::GET_RABBIT_NAME, BAD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::NoGoodTokenOrSerial, rsp
  end


  def test_wrong_token
    rsp = Request::Query.new(Request::GET_RABBIT_NAME, GOOD_SERIAL, BAD_TOKEN).send!
    assert_instance_of Response::NoGoodTokenOrSerial, rsp
  end


  def test_GET_LINKPREVIEW
    rsp = Request::Query.new(Request::GET_LINKPREVIEW, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::LinkPreview, rsp
  end

  def test_GET_FRIENDS_LIST
    rsp = Request::Query.new(Request::GET_FRIENDS_LIST, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::ListFriend, rsp
  end

  def test_GET_INBOX_LIST
    rsp = Request::Query.new(Request::GET_INBOX_LIST, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::ListReceivedMsg, rsp
  end

  def test_GET_TIMEZONE
    rsp = Request::Query.new(Request::GET_TIMEZONE, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::Timezone, rsp
  end

  def test_GET_SIGNATURE
    rsp = Request::Query.new(Request::GET_SIGNATURE, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::Signature, rsp
  end

  def test_GET_BLACKLISTED
    rsp = Request::Query.new(Request::GET_BLACKLISTED, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::Blacklist, rsp
  end

  def test_GET_RABBIT_STATUS
    rsp = Request::Query.new(Request::GET_RABBIT_STATUS, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::RabbitSleep, rsp
  end

  def test_GET_LANG_VOICE
    rsp = Request::Query.new(Request::GET_LANG_VOICE, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::VoiceListTts, rsp
  end

  def test_GET_RABBIT_NAME
    rsp = Request::Query.new(Request::GET_RABBIT_NAME, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::RabbitName, rsp
  end

  def test_GET_SELECTED_LANG
    rsp = Request::Query.new(Request::GET_SELECTED_LANG, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::LangListUser, rsp
  end

  def test_GET_MESSAGE_PREVIEW
    rsp = Request::Query.new(Request::GET_MESSAGE_PREVIEW, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::LinkPreview, rsp
  end

  def test_GET_EARS_POSITION
    rsp = Request::Query.new(Request::GET_EARS_POSITION, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::PositionEar, rsp
  end

  def test_SET_RABBIT_ASLEEP
    rsp = Request::Query.new(Request::SET_RABBIT_ASLEEP, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::CommandSend, rsp
  end

  def test_SET_RABBIT_AWAKE
    rsp = Request::Query.new(Request::SET_RABBIT_AWAKE, GOOD_SERIAL, GOOD_TOKEN).send!
    assert_instance_of Response::CommandSend, rsp
  end
end
