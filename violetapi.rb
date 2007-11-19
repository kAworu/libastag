
# TODO
module VioletAPI

  # the VioletAPI url.
  # see http://api.nabaztag.com/docs/home.html#sendevent
  URL = 'http://api.nabaztag.com/vl/FR/api.jsp?'



  # TODO
  module Core

    # abstract class.
    # All class that send a message to Violet
    # should inherit of #Event.
    class Event
      # constructor has to bee overrided.
      def initialize
        raise NotImplementedError
      end

      # #to_url has to bee overrided.
      def to_url
        raise NotImplementedError
      end
    end


    # combine many #Event.
    # #Event can be combined in a single
    # request.
    class EventNode < Event
      include Enumerable

      # chilldens.
      attr_reader :events

      # create a new #EventNode with
      # +args+ childrens.
      def initialize *args
        @events = args end

      # Add a +event+ to self.
      def <<(event)
        @events << event
      end

      # We have to define #EventNode#each to
      # include #Enumerable.
      def each
        @events.each { |e| yield e }
      end

      # override #Event#to_url.
      def to_url
        self.collect { |e| e.to_url }.join
      end
    end

  end # module Core



  # actions are used to retrieve informations about the
  # Nabaztag or the Nabaztag's owners.
  # see http://api.nabaztag.com/docs/home.html#getinfo
  module Action

    class ActionEvent < Core::Event
      # create a new #Action with +id+
      # see http://api.nabaztag.com/docs/home.html#getinfo
      # for ids.
      def initialize id
        @id = id
      end

      # override #Event#to_url.
      def to_url
        "&action=#{@id}"
      end
    end


    # Preview the TTS or music (with music id) without sending it
    # see #Response::LinkPreview
    GET_LINKPREVIEW = ActionEvent.new 1

    # Get a list of your friends
    # see #Response::FriendList
    GET_FRIENDS_LIST = ActionEvent.new 2

    # Get a count and the list of the messages in your inbox
    # see #Response::RecivedMsgList
    GET_INBOX_LIST = ActionEvent.new 3

    # Get the timezone in which your Nabaztag is set
    # see #Response::NabaTimezone
    GET_TIMEZONE = ActionEvent.new 4

    # Get the signature defined for the Nabaztag
    # see #Response::NabaSignature
    GET_SIGNATURE = ActionEvent.new 5

    # Get a count and the list of people in your blacklist
    # see #Response::NabaBlacklist
    GET_BLACKLISTED = ActionEvent.new 6

    # Get to know if the Nabaztag is sleeping (YES) or not (NO)
    # see Response::RabbitSleep
    GET_RABBIT_STATUS = ActionEvent.new 7

    # Get to know if the Nabaztag is a Nabaztag (V1) or a Nabaztag/tag (V2)
    # see Response::RabbitVersion
    GET_RABBIT_VERSION = ActionEvent.new 8

    # Get a list of all supported languages/voices for TTS (text to speach) engine
    # see Response::TtsVoiceList
    GET_LANG_VOICE = ActionEvent.new 9

    # Get the name of the Nabaztag
    # see Response::NabName
    GET_RABBIT_NAME = ActionEvent.new 10

    # Get the languages selected for the Nabaztag
    # see Response::UserLangList
    GET_SELECTED_LANG = ActionEvent.new 11

    # Get a preview of a message. This works only with the urlPlay parameter and URLs like broad/001/076/801/262.mp3
    # see Response::LinkPreview
    GET_MESSAGE_PREVIEW = ActionEvent.new 12

    # Send your Rabbit to sleep
    # see Response::CommandSend
    SET_RABBIT_ASLEEP = ActionEvent.new 13

    #  Wake up your Rabbit
    # see Response::CommandSend
    SET_RABBIT_AWAKE = ActionEvent.new 14

  end # module Action



  # TODO
  module Response

    # a #ProtocolExcepion object is raised if server
    # return a unhandled response.
    # see http://api.nabaztag.com/docs/home.html#messages
    class ProtocolExcepion < Exception; end


    # abstract class.
    # base class used to handle Violet
    # server's responses
    class ServerRsp
      # String: response message element.
      attr_reader :message
      # String: response comment element.
      attr_reader :comment

      # create a new #ServerRsp. parse
      # the given +xml+ to set +comment+ and
      # +message+. must be overrided if self
      # is not a simple server's response.
      def initialize xml
        require 'rexml/document'
        begin
          @xml = REXML::Document.new xml
        rescue REXML::ParseException => e
          raise ProtocolExcepion.new e.message
        end
        @message = @xml.elements['//message'].text
        @comment = @xml.elements['//comment'].text
      end

      # return +true+ if the response is not an
      # error, +false+ otherwhise.
      def good?
        raise NotImplementedError
      end

      # return +true+ if the response is an
      # error, +false+ otherwhise.
      def bad?
        not self.good?
      end
    end


    # handle Errors messages of Violet server.
    # see http://api.nabaztag.com/docs/home.html#messages
    class BadServerRsp < ServerRsp
      # override #ServerRsp#good?
      def good?
        false
      end
    end


    # handle server messages of Violet
    class GoodServerRsp < ServerRsp
      # override #ServerRsp#good?
      def good?
        true
      end
    end


    # Too much requests sent
    class AbuseSending < BadServerRsp; end
    # Wrong token or serial number 
    class NoGoodSerialOrToken < BadServerRsp; end
    # Wrong music id (either not in your personal MP3s list or not existing)
    class MessageNotSend < BadServerRsp; end
    #  urlList parameter missing (api_stream)
    class NoCorrectParameters < BadServerRsp; end
    # The rabbit is not a Nabaztag/tag
    class NotV2Rabbit < BadServerRsp; end
    # Nabcast not posted because music id is not part of your personal MP3s or because the nabcast id does not belong to you or is not existing
    class NabCastNotSend < BadServerRsp; end
    # Message not sent
    class MessageNotSend < BadServerRsp; end
    # TTS creation problem or TTS not send
    class TtsNotSend < BadServerRsp; end
    # Choregraphy message not sent because the "chor" command was incorrect
    class ChorNotSend < BadServerRsp; end
    # Ears position not sent because the given position is incorrect
    class EarPositionNotSend < BadServerRsp; end
    # URL was not sent (api_stream)
    class WebRadioNotSend < BadServerRsp; end

    # Nabcast posted
    class NabCastSend < GoodServerRsp; end
    # TODO
    class CommandSend < GoodServerRsp; end
    # Message sent
    class MessageSend < GoodServerRsp; end
    # TTS message sent
    class TtsSend < GoodServerRsp; end
    # Choregraphy message sent
    class ChorSend < GoodServerRsp; end
    # Ears position sent
    class EarPositionSend < GoodServerRsp; end
    # URL was sent (api_stream)
    class WebRadioSend < GoodServerRsp; end
    # Preview the TTS or music (with music id) without sending it
    class LinkPreview < GoodServerRsp; end

    # Getting the ears position
    class PositionEar < GoodServerRsp
      # Fixnum: position of the left ear.
      attr_reader :leftposition
      # Fixnum: position of the left ear.
      attr_reader :rightposition

      # set +leftposition+ and +right
      def initialize xml
        super # to set @message and @xml
        @leftposition   = @xml.elements['//leftposition' ].text.to_i
        @rightposition  = @xml.elements['//rightposition'].text.to_i
      end
    end

    # Getting friends list
    class FriendList < GoodServerRsp
        # TODO
    end

    # TODO
    class RecivedMsgList < GoodServerRsp
      # TODO
    end

    # TODO
    class NabaTimezone < GoodServerRsp
      # TODO
    end

    # TODO
    class NabaSignature < GoodServerRsp
      # TODO
    end

    # TODO
    class NabaBlacklist < GoodServerRsp
      # TODO
    end

    # TODO
    class RabbitSleep < GoodServerRsp
      # TODO
    end

    # TODO
    class RabbitVersion < GoodServerRsp
      # TODO
    end

    # TODO
    class TtsVoiceList < GoodServerRsp
      # TODO
    end

    # TODO
    class NabName < GoodServerRsp
      # TODO
    end

    # TODO
    class UserLangList < GoodServerRsp
      # TODO
    end

  end # module Response



  # this class is used to "translate" our #Events into URLs.
  # see http://api.nabaztag.com/docs/home.html
  class Query

    # create a new Query with the give +event+, +serial+, and +token+.
    # +serial+ and +token+ parameters should be checked at a higher level.
    def initialize(event, serial, token)
      @event, @serial, @token = event, serial, token
    end

    def to_url
      Base::URL + "&token=#{@token}" + "&sn=#{@serial}" + @event.to_url
    end
  end


  def send! query
    require 'open-uri'
    response = open(query.to_url) { |r| r.read }
    parse!(response)
  end


  private

  # Parse server's response (xml) to a query
  # and return a #ServerResponse.
  def parse!
  end

end # VioletAPI

=begin
    DESC = {
            :sn             => "Serial number of the Nabaztag that will receive events"
            :token          => "The token is a series of digits given when you activate the Nabaztag receiver. This extra identification limits the risks of spam, since, in order to send a message, you need to know both the serial number and the token"
            :idmessage      => "The number of the message to send. This number can refer to a message in the Library or a personal MP3 file that you have downloaded. You find this identification number under the title of the track you are listening to"
            :nabcast        => "Id of your nabcast (if you want to publish a content in your nabcast)"
            :nabcasttitl    => "Title of the post in your nabcast"
            :posright       => "Position of the right ear between 0 and 16 (0 = ear vertical)"
            :posleft        => "Position of the left ear between 0 and 16 (0 = ear vertical)"
            :ears           => "Send the position of the ears to your Nabaztag"
            :idapp          => "This is your application ID. It will allow you to authenticate the event's transmitter. This parameter is not yet in service"
            :voice          => "Allows you to choose the voice that will read the message"
            :tts            => "Allows you to send a text configured for speech synthesis"
            :speed          => "Allows you to choose the reading speed of the message.Values ranging from 1 to 32000. Default is 100."
            :pitch          => "Allows you to modulate the voice's frequency. Values ranging from 1 to 32000. Default is 100."
            :chor           => "Sending a choreography to your Nabaztag"
            :chortitle      => "The name of the choreography"
            :ttlive         => "Allows you to define the length of time you want a message to remain on the site (in seconds). By default, the message will be stored for a period of two months"
            :action         => "Retrieving info from your Nabaztag",
    }
=end

