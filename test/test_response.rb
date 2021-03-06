#!/usr/bin/ruby


$LOAD_PATH.unshift File.join( File.dirname(__FILE__), '..', 'lib' )


require 'libastag/response'

require 'test/unit'



class ResponseTest < Test::Unit::TestCase

  def test_bad_protocol
    assert_raise(Libastag::Response::ProtocolExcepion) { Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><comment>a comment without messages</comment></rsp>' }
    assert_raise(Libastag::Response::ProtocolExcepion) { Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><friend name="toto"/><friend name="tata"/></rsp>' }
  end

  
  def test_invalid_xml
    assert_raise(REXML::ParseException) { Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><open></rsp>' }
  end


  def test_simple_case
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>'
    assert_kind_of Libastag::Response::Base::ServerRsp, rsp
  end


  def test_get_all
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>'
    assert_equal 'YES', rsp.get_all(:rabbitSleep) { |e| e.text }.first

    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>LINKPREVIEW</message><comment>a comment</comment></rsp>'
    assert_equal 'LINKPREVIEW', rsp.get_all(:message) { |e| e.text }.first
    assert_equal 'a comment', rsp.get_all(:comment) { |e| e.text }.first

    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listfriend nb="2"/><friend name="toto"/><friend name="tata"/></rsp>'
    assert_equal({:nb => '2'}, rsp.get_all(:listfriend) { |e| e.attributes.to_hash }.first)
    assert_equal [{:name => 'toto'},{:name => 'tata'}], rsp.get_all(:friend) { |e| e.attributes.to_hash }
  end


  def test_undefined_element
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>'
    assert_raise(NameError) { rsp.comment }
    assert_raise(NameError) { rsp.message }
  end


  def test_has_and_has_many
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>LINKPREVIEW</message><comment>a comment</comment></rsp>'
    assert rsp.has_message?
    assert !rsp.has_messages?
    assert !rsp.has_many_messages?
    assert rsp.has_comment?
    assert !rsp.has_comments?
    assert !rsp.has_many_comments?

    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listfriend nb="2"/><friend name="toto"/><friend name="tata"/></rsp>'
    assert rsp.has_listfriend?
    assert !rsp.has_listfriends?
    assert !rsp.has_many_listfriends?
    assert rsp.has_friend?
    assert !rsp.has_friends?
    assert rsp.has_many_friends?
  end


  def test_accessors_message_and_comment
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NABCASTNOTSENT</message><comment>Your idmessage is private</comment></rsp>'
    assert_equal 'NABCASTNOTSENT', rsp.message
    assert_equal 'Your idmessage is private', rsp.comment 
  end


  def test_accessors_with_hash
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listfriend nb="3"/><friend name="toto"/><friend name="tata"/><friend name="titi"/></rsp>'
    assert_equal({:nb => '3'}, rsp.listfriend)
    assert_equal({:name => 'toto'}, rsp.friend)
    assert_equal [{:name => 'toto'}, {:name => 'tata'}, {:name => 'titi'}], rsp.friends
    assert_equal rsp.listfriend[:nb], rsp.friends.size.to_s

    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listreceivedmsg nb="1"/><msg from="toto" title="my message" date="today 11:59" url="broad/001/948.mp3"/></rsp>'
    assert_equal rsp.listreceivedmsg, {:nb => '1'}
    assert_equal({:from => 'toto', :title => 'my message', :date => 'today 11:59', :url => 'broad/001/948.mp3'}, rsp.msg)
    assert_equal rsp.listreceivedmsg[:nb].to_i, rsp.msgs.size
  end

  def test_good
    rsp = Libastag::Response::Base::GoodServerRsp.new(String.new)
    assert rsp.good?
    assert !rsp.bad?
  end


  def test_bad
    rsp = Libastag::Response::Base::BadServerRsp.new(String.new)
    assert rsp.bad?
    assert !rsp.good?
  end


  def test_EmptyServerRsp
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp></rsp>'
    rsp2 = Libastag::Response.parse %{<?xml version="1.0" encoding="UTF-8"?><rsp>  \n \n </rsp>}

    assert_instance_of Libastag::Response::EmptyServerRsp, rsp
    assert_instance_of Libastag::Response::EmptyServerRsp, rsp2
    assert !rsp.good?
    assert !rsp.bad?
  end

  
  def test_LinkPreview
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>LINKPREVIEW</message><comment>a comment</comment></rsp>'
    assert_instance_of  Libastag::Response::LinkPreview, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_ListFriend
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listfriend nb="3"/><friend name="toto"/><friend name="tata"/><friend name="titi"/></rsp>'
    assert_instance_of  Libastag::Response::ListFriend, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_ListReceivedMsg
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><listreceivedmsg nb="1"/><msg from="toto" title="my message" date="today 11:59" url="broad/001/948.mp3"/></rsp>'
    assert_instance_of  Libastag::Response::ListReceivedMsg, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp

  end

  def test_Timezone
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><timezone>(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London</timezone></rsp>'
    assert_instance_of  Libastag::Response::Timezone, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_Signature
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><signature>my pretty signature !</signature></rsp> '
    assert_instance_of  Libastag::Response::Signature, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_Blacklist
  rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><blacklist nb="3"/><pseudo name="bill"/><pseudo name="steve"/><pseudo name="paul"/></rsp>'
    assert_instance_of  Libastag::Response::Blacklist, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_RabbitSleep
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>'
    assert_instance_of  Libastag::Response::RabbitSleep, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_RabbitVersion
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitVersion>V2</rabbitVersion></rsp>'
    assert_instance_of  Libastag::Response::RabbitVersion, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_VoiceListTTS
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><voiceListTTS nb="2"/><voice lang="fr" command="claire22k"/><voice lang="de" command="helga22k"/></rsp>'
    assert_instance_of  Libastag::Response::VoiceListTts, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_RabbitName
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitName>Theo</rabbitName></rsp>'
    assert_instance_of  Libastag::Response::RabbitName, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_LangListUser
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><langListUser nb="4"/><myLang lang="fr"/><myLang lang="us"/><myLang lang="uk"/><myLang lang="de"/></rsp>'
    assert_instance_of  Libastag::Response::LangListUser, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_CommandSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>COMMANDSENT</message><comment>You rabbit will change status</comment></rsp>'
    assert_instance_of  Libastag::Response::CommandSent, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_AbuseSending
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>ABUSESENDING</message><comment>Too much message sending,try later</comment></rsp>'
    assert_instance_of  Libastag::Response::AbuseSending, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_NoGoodTokenOrSerial
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NOGOODTOKENORSERIAL</message><comment>Your token or serial number are not correct !</comment></rsp>'
    assert_instance_of  Libastag::Response::NoGoodTokenOrSerial, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_MessageNotSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>MESSAGENOTSENT</message><comment>Your idmessage is not correct or is private</comment></rsp>'
    assert_instance_of  Libastag::Response::MessageNotSent, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_NabCastNotSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NABCASTNOTSENT</message><comment>Your idmessage is private</comment></rsp>'
    assert_instance_of  Libastag::Response::NabCastNotSent, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_NabCastSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NABCASTSENT</message><comment>Your nabcast has been sent</comment></rsp>'
    assert_instance_of  Libastag::Response::NabCastSent, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end
  
  def test_MessageSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>MESSAGESENT</message><comment>Your message has been sent</comment></rsp>'
    assert_instance_of  Libastag::Response::MessageSent, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_TtsNotSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>TTSNOTSENT</message><comment>Your text could not be sent</comment></rsp>'
    assert_instance_of  Libastag::Response::TtsNotSent, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_TtsSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>TTSSENT</message><comment>Your text has been sent</comment></rsp>'
    assert_instance_of  Libastag::Response::TtsSent, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_ChorSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>CHORSENT</message><comment>Your chor has been sent</comment></rsp>'
    assert_instance_of  Libastag::Response::ChorSent, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_ChorNotSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>CHORNOTSENT</message><comment>Your chor could not be sent (bad chor)</comment></rsp>'
    assert_instance_of  Libastag::Response::ChorNotSent, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_EarPositionSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>EARPOSITIONSENT</message><comment>Your ears command has been sent</comment></rsp>'
    assert_instance_of  Libastag::Response::EarPositionSent, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_EarPositionNotSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>EARPOSITIONNOTSENT</message><comment>Your ears command could not be sent</comment></rsp>'
    assert_instance_of  Libastag::Response::EarPositionNotSent, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_PositionEar
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>POSITIONEAR</message><leftposition>8</leftposition><rightposition>10</rightposition></rsp>'
    assert_instance_of  Libastag::Response::PositionEar, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_WebRadioSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>WEBRADIOSENT</message><comment>Your webradio has been sent</comment></rsp>'
    assert_instance_of  Libastag::Response::WebRadioSent, rsp
    assert_kind_of      Libastag::Response::Base::GoodServerRsp, rsp
  end

  def test_WebRadioNotSent
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>WEBRADIONOTSENT</message><comment>Your webradio could not be sent</comment></rsp>'
    assert_instance_of  Libastag::Response::WebRadioNotSent, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_NoCorrectParameters
    rsp = Libastag::Response.parse ' <?xml version="1.0" encoding="UTF-8"?><rsp><message>NOCORRECTPARAMETERS</message><comment>Please check urlList parameter !</comment></rsp>'
    assert_instance_of  Libastag::Response::NoCorrectParameters, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

  def test_NotV2Rabbit
    rsp = Libastag::Response.parse '<?xml version="1.0" encoding="UTF-8"?><rsp><message>NOTV2RABBIT</message><comment>V2 rabbit can use this action</comment></rsp>'
    assert_instance_of  Libastag::Response::NotV2Rabbit, rsp
    assert_kind_of      Libastag::Response::Base::BadServerRsp, rsp
  end

end

