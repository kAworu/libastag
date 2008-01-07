#!/usr/bin/ruby


def from_this_file_path *args
  File.join( File.dirname(__FILE__), *args )
end


require from_this_file_path('..', 'lib', 'violet', 'request',  'request.rb' )
require from_this_file_path('..', 'lib', 'violet', 'response', 'response.rb')

require 'test/unit'




class RequestStuffTest < Test::Unit::TestCase
  include Request

  def test_SetEarsPosition_new
    assert_equal 0,  SetEarsPosition::MIN_POS
    assert_equal 16, SetEarsPosition::MAX_POS

    min, max = SetEarsPosition::MIN_POS, SetEarsPosition::MAX_POS


    [:posleft, :posright].each do |sym|
      assert_raise(ArgumentError) { SetEarsPosition.new }
      assert_raise(ArgumentError) { SetEarsPosition.new sym => (min-1) }
      assert_raise(ArgumentError) { SetEarsPosition.new sym => (max+1) }
    end

    assert_nothing_raised do
      SetEarsPosition.new :posleft  => min
      SetEarsPosition.new :posright => max
      SetEarsPosition.new :posright => min, :posleft => max
    end
  end

  
  def test_SetEarsPosition
    e = SetEarsPosition.new :posleft => 12, :posright => 1.1
    assert_equal ['posleft=12','posright=1'], e.to_url
  end


  def test_TtsMessage_new
    assert_equal 1,     TtsMessage::MIN_PITCH
    assert_equal 32000, TtsMessage::MAX_PITCH
    assert_equal 1,     TtsMessage::MIN_PITCH
    assert_equal 32000, TtsMessage::MAX_PITCH

    assert_raise(ArgumentError) { TtsMessage.new }
    assert_raise(ArgumentError) { TtsMessage.new :tts => '', :speed => (TtsMessage::MAX_SPEED) +1 }
    assert_raise(ArgumentError) { TtsMessage.new :tts => '', :speed => (TtsMessage::MIN_SPEED) -1 }
    assert_raise(ArgumentError) { TtsMessage.new :tts => '', :pitch => (TtsMessage::MAX_PITCH) +1 }
    assert_raise(ArgumentError) { TtsMessage.new :tts => '', :pitch => (TtsMessage::MIN_PITCH) -1 }

    assert_nothing_raised do
      TtsMessage.new :tts => 'foo'
      TtsMessage.new :tts => 'foo', :pitch => TtsMessage::MIN_PITCH
      TtsMessage.new :tts => 'foo', :pitch => TtsMessage::MAX_PITCH
      TtsMessage.new :tts => 'foo', :speed => TtsMessage::MIN_PITCH
      TtsMessage.new :tts => 'foo', :speed => TtsMessage::MAX_PITCH
    end
  end


  def test_TtsMessage
    e     = nil
    tts   = 'Hello world'
    assert_nothing_raised { e = TtsMessage.new :tts => tts }
    assert_equal ["tts=#{URI.escape(tts)}"], e.to_url

    pitch = 12
    speed = 11.1
    assert_nothing_raised do
      e = TtsMessage.new    :tts    => tts,
                            :speed  => speed,
                            :pitch  => pitch
    end
    assert_equal ["pitch=#{pitch}","speed=#{speed.to_i}","tts=#{URI.escape(tts)}"], e.to_url
  end


  def test_TtsMessage_with_nabcast
    title = 'this is a test'
    msg   = 'wow ! a message !'
    t     = nil

    assert_nothing_raised do
      TtsMessage.new :tts => msg, :nabcast => 12
      TtsMessage.new :tts => msg, :nabcast => 12, :nabcasttitle => title
      t = TtsMessage.new :tts => msg, :nabcast => 12, :nabcasttitle => title, :pitch => 42, :speed => 120
    end

    expected = ['nabcast=12',"nabcasttitle=#{URI.escape(title)}",'pitch=42','speed=120',"tts=#{URI.escape(msg)}"]
    assert_equal expected, t.to_url
  end


  def test_IdMessage_new
    assert_equal 1, IdMessage::MIN_IDMESSAGE

    assert_raise(ArgumentError) { IdMessage.new }
    assert_raise(ArgumentError) { IdMessage.new :idmessage => (IdMessage::MIN_IDMESSAGE)-1 }
    assert_nothing_raised { IdMessage.new :idmessage => IdMessage::MIN_IDMESSAGE }
  end


  def test_IdMessage_with_nabcast
    id      = 1337
    nabcast = 118218
    title   = "it's gonna rain"

    assert_equal ['idmessage=1337'], IdMessage.new(:idmessage => id).to_url

    i = IdMessage.new :idmessage => id, :nabcast => nabcast, :nabcasttitle => title
    assert_equal [ 'idmessage=1337', "nabcast=#{nabcast}", "nabcasttitle=#{URI.escape(title)}"], i.to_url
  end
end
