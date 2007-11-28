#!/usr/bin/ruby


def from_this_file_path *args
  File.join( File.dirname(__FILE__), *args )
end


require from_this_file_path('..', 'lib', 'violet', 'response.rb')

require 'test/unit'



class ResponseTest < Test::Unit::TestCase

  def test_bad_protocol
    assert_raise(Response::ProtocolExcepion) { Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><comment>a comment without messages</comment></rsp>' }
    assert_raise(Response::ProtocolExcepion) { Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><friend name="toto"/><friend name="tata"/></rsp>' }
  end

  
  def test_invalid_xml
    assert_raise(REXML::ParseException) { Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><open></rsp>' }
  end


  def test_simple_case
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>'
    assert_kind_of Response::Base::ServerRsp, rsp
  end


  def test_get_all
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>'
    assert_equal 'YES', rsp.get_all(:rabbitSleep) { |e| e.text }.first

    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>LINKPREVIEW</message><comment>a comment</comment></rsp>'
    assert_equal 'LINKPREVIEW', rsp.get_all(:message) { |e| e.text }.first
    assert_equal 'a comment', rsp.get_all(:comment) { |e| e.text }.first

    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listfriend nb="2"/><friend name="toto"/><friend name="tata"/></rsp>'
    assert_equal({:nb => '2'}, rsp.get_all(:listfriend) { |e| e.attributes.to_hash }.first)
    assert_equal [{:name => 'toto'},{:name => 'tata'}], rsp.get_all(:friend) { |e| e.attributes.to_hash }
  end


  def test_undefined_element
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>'
    assert_raise(NameError) { rsp.comment }
    assert_raise(NameError) { rsp.message }
  end


  def test_has_and_has_many
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>LINKPREVIEW</message><comment>a comment</comment></rsp>'
    assert rsp.has_message?
    assert !rsp.has_messages?
    assert !rsp.has_many_messages?
    assert rsp.has_comment?
    assert !rsp.has_comments?
    assert !rsp.has_many_comments?

    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listfriend nb="2"/><friend name="toto"/><friend name="tata"/></rsp>'
    assert rsp.has_listfriend?
    assert !rsp.has_listfriends?
    assert !rsp.has_many_listfriends?
    assert rsp.has_friend?
    assert !rsp.has_friends?
    assert rsp.has_many_friends?
  end


  def test_accessors_message_and_comment
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NABCASTNOTSEND</message><comment>Your idmessage is private</comment></rsp>'
    assert_equal 'NABCASTNOTSEND', rsp.message
    assert_equal 'Your idmessage is private', rsp.comment 
  end


  def test_accessors_with_hash
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listfriend nb="3"/><friend name="toto"/><friend name="tata"/><friend name="titi"/></rsp>'
    assert_equal({:nb => '3'}, rsp.listfriend)
    assert_equal({:name => 'toto'}, rsp.friend)
    assert_equal [{:name => 'toto'}, {:name => 'tata'}, {:name => 'titi'}], rsp.friends
    assert_equal rsp.listfriend[:nb], rsp.friends.size.to_s

    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listreceivedmsg nb="1"/><msg from="toto" title="my message" date="today 11:59" url="broad/001/948.mp3"/></rsp>'
    assert_equal rsp.listreceivedmsg, {:nb => '1'}
    assert_equal({:from => 'toto', :title => 'my message', :date => 'today 11:59', :url => 'broad/001/948.mp3'}, rsp.msg)
    assert_equal rsp.listreceivedmsg[:nb].to_i, rsp.msgs.size
  end

  def test_good
    rsp = Response::Base::GoodServerRsp.new(String.new)
    assert rsp.good?
    assert !rsp.bad?
  end


  def test_bad
    rsp = Response::Base::BadServerRsp.new(String.new)
    assert rsp.bad?
    assert !rsp.good?
  end


  def test_EmptyServerRsp
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp></rsp>'

    assert_instance_of Response::EmptyServerRsp, rsp
    assert !rsp.good?
    assert !rsp.bad?
  end


  def test_LinkPreview
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>LINKPREVIEW</message><comment>a comment</comment></rsp>'
    assert_instance_of  Response::LinkPreview, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_ListFriend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listfriend nb="3"/><friend name="toto"/><friend name="tata"/><friend name="titi"/></rsp>'
    assert_instance_of  Response::ListFriend, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_ListReceivedMsg
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listreceivedmsg nb="1"/><msg from="toto" title="my message" date="today 11:59" url="broad/001/948.mp3"/></rsp>'
    assert_instance_of  Response::ListReceivedMsg, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp

  end

  def test_Timezone
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><timezone>(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London</timezone></rsp>'
    assert_instance_of  Response::Timezone, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_Signature
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><signature>my pretty signature !</signature></rsp> '
    assert_instance_of  Response::Signature, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_Blacklist
  rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><blacklist nb="3"/><pseudo name="bill"/><pseudo name="steve"/><pseudo name="paul"/></rsp>'
    assert_instance_of  Response::Blacklist, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_RabbitSleep
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>'
    assert_instance_of  Response::RabbitSleep, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_RabbitVersion
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitVersion>V2</rabbitVersion></rsp>'
    assert_instance_of  Response::RabbitVersion, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_VoiceListTTS
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><voiceListTTS nb="2"/><voice lang="fr" command="claire22k"/><voice lang="de" command="helga22k"/></rsp>'
    assert_instance_of  Response::VoiceListTts, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_RabbitName
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitName>Theo</rabbitName></rsp>'
    assert_instance_of  Response::RabbitName, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_LangListUser
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><langListUser nb="4"/><myLang lang="fr"/><myLang lang="us"/><myLang lang="uk"/><myLang lang="de"/></rsp>'
    assert_instance_of  Response::LangListUser, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_CommandSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>COMMANDSEND</message><comment>You rabbit will change status</comment></rsp>'
    assert_instance_of  Response::CommandSend, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_AbuseSending
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>ABUSESENDING</message><comment>Too much message sending,try later</comment></rsp>'
    assert_instance_of  Response::AbuseSending, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_NoGoodTokenOrSerial
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NOGOODTOKENORSERIAL</message><comment>Your token or serial number are not correct !</comment></rsp>'
    assert_instance_of  Response::NoGoodTokenOrSerial, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_MessageNotSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>MESSAGENOTSEND</message><comment>Your idmessage is not correct or is private</comment></rsp>'
    assert_instance_of  Response::MessageNotSend, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_NabCastNotSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NABCASTNOTSEND</message><comment>Your idmessage is private</comment></rsp>'
    assert_instance_of  Response::NabCastNotSend, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_NabCastSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NABCASTSEND</message><comment>Your nabcast has been sent</comment></rsp>'
    assert_instance_of  Response::NabCastSend, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end
  
  def test_MessageSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>MESSAGESEND</message><comment>Your message has been sent</comment></rsp>'
    assert_instance_of  Response::MessageSend, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_TtsNotSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>TTSNOTSEND</message><comment>Your text could not be sent</comment></rsp>'
    assert_instance_of  Response::TtsNotSend, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_TtsSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>TTSSEND</message><comment>Your text has been sent</comment></rsp>'
    assert_instance_of  Response::TtsSend, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_ChorSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>CHORSEND</message><comment>Your chor has been sent</comment></rsp>'
    assert_instance_of  Response::ChorSend, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_ChorNotSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>CHORNOTSEND</message><comment>Your chor could not be sent (bad chor)</comment></rsp>'
    assert_instance_of  Response::ChorNotSend, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_EarPositionSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>EARPOSITIONSEND</message><comment>Your ears command has been sent</comment></rsp>'
    assert_instance_of  Response::EarPositionSend, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_EarPositionNotSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>EARPOSITIONNOTSEND</message><comment>Your ears command could not be sent</comment></rsp>'
    assert_instance_of  Response::EarPositionNotSend, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_PositionEar
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>POSITIONEAR</message><leftposition>8</leftposition><rightposition>10</rightposition></rsp>'
    assert_instance_of  Response::PositionEar, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_WebRadioSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>WEBRADIOSEND</message><comment>Your webradio has been sent</comment></rsp>'
    assert_instance_of  Response::WebRadioSend, rsp
    assert_kind_of      Response::Base::GoodServerRsp, rsp
  end

  def test_WebRadioNotSend
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>WEBRADIONOTSEND</message><comment>Your webradio could not be sent</comment></rsp>'
    assert_instance_of  Response::WebRadioNotSend, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_NoCorrectParameters
    rsp = Response.parse ' <?xml version="1.0" encoding="UTF-8"?><rsp><message>NOCORRECTPARAMETERS</message><comment>Please check urlList parameter !</comment></rsp>'
    assert_instance_of  Response::NoCorrectParameters, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

  def test_NotV2Rabbit
    rsp = Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NOTV2RABBIT</message><comment>V2 rabbit can use this action</comment></rsp>'
    assert_instance_of  Response::NotV2Rabbit, rsp
    assert_kind_of      Response::Base::BadServerRsp, rsp
  end

end

