=begin Draw
TODO
=end


# TODO
module VioletAPI



  # contains events to send to the server.  #Action
  # instances are constants, because they're always
  # the same request, but other #Event derivated
  # class are used to create objects.
  module Request

  # the VioletAPI url where we send request.
  # see http://api.nabaztag.com/docs/home.html#sendevent
  URL = 'http://api.nabaztag.com/vl/FR/api.jsp?'


    ## Basic class
    # contains some basic stuff, abstract class
    # etc. they're used internaly and you should
    # only use derivated class.
    module Base

      ## abstract class.
      # All class that send a message to Violet
      # should inherit of this class.
      class Event
        # constructor has to be overrided
        def initialize
          raise NotImplementedError
        end

        # TODO
        def + other
          EventCollection.new self, other
        end
        # to_url has to be overrided
        def to_url
          raise NotImplementedError
        end
      end


      # combine many #Event in a single request
      class EventCollection < Event
        include Enumerable

        # create a new EventCollection with
        # two childrens.
        def initialize one, another
          if one.respond_to?(:to_url) and another.respond_to?(:to_url) # Coin Coin ! >°_/
            @childrens = [ one, another ]
          else
            raise ArgumentError.new, "bad parameters"
          end
        end

        # We have to define each to include
        # #Enumerable module.
        def each
          @childrens.each do |e|
            if e.kind_of? Enumerable
              e.each { |i| yield i }
            else
              yield e
            end
          end
        end

        # override #Event#to_url.
        def to_url
          @childrens.collect { |e| e.to_url }.join('&')
        end
      end

    end # module Request::Base


    # this class is used to "translate" our #Events
    # into URLs.
    # see http://api.nabaztag.com/docs/home.html
    class Query
      # create a new Query with the give +event+,
      # +serial+, and +token+.  +serial+ and +token+
      # parameters should be checked at a higher
      # level.
      def initialize(event, serial, token)
        @event, @serial, @token = event, serial, token
      end

      # TODO
      def to_url
        [ VioletAPI::Request::URL, "token=#{@token}", "sn=#{@serial}", @event.to_url ].join('&')
      end
    end


    # actions are used to retrieve
    # informations about the Nabaztag
    # or the Nabaztag's owners. see
    # http://api.nabaztag.com/docs/home.html#getinfo
    class Action < Base::Event
      # create a new #Action with +id+
      def initialize id
        @id = id
      end

      # override #Event#to_url.
      def to_url
        "action=#{@id}"
      end
    end

    #
    # actions list.
    # TODO: speack about GET_EARS_POSITION
    # http://api.nabaztag.com/docs/home.html#getinfo
    #


    # Preview the TTS or music (with music id)
    # without sending it
    # see #Response::LinkPreview
    GET_LINKPREVIEW = Action.new 1

    # Get a list of your friends
    # see #Response::FriendList
    GET_FRIENDS_LIST = Action.new 2

    # Get a count and the list of the messages
    # in your inbox
    # see #Response::RecivedMsgList
    GET_INBOX_LIST = Action.new 3

    # Get the timezone in which your Nabaztag
    # is set
    # see #Response::NabaTimezone
    GET_TIMEZONE = Action.new 4

    # Get the signature defined for the Nabaztag
    # see #Response::NabaSignature
    GET_SIGNATURE = Action.new 5

    # Get a count and the list of people in
    # your blacklist
    # see #Response::NabaBlacklist
    GET_BLACKLISTED = Action.new 6

    # Get to know if the Nabaztag is sleeping
    # (YES) or not (NO)
    # see #Response::RabbitSleep
    GET_RABBIT_STATUS = Action.new 7

    # Get to know if the Nabaztag is a Nabaztag
    # (V1) or a Nabaztag/tag (V2)
    # see #Response::RabbitVersion
    GET_RABBIT_VERSION = Action.new 8

    # Get a list of all supported
    # languages/voices for TTS (text to speach)
    # engine
    # see #Response::TtsVoiceList
    GET_LANG_VOICE = Action.new 9

    # Get the name of the Nabaztag
    # see #Response::NabName
    GET_RABBIT_NAME = Action.new 10

    # Get the languages selected for the Nabaztag
    # see #Response::UserLangList
    GET_SELECTED_LANG = Action.new 11

    # Get a preview of a message. This works only
    # with the urlPlay parameter and URLs like
    # broad/001/076/801/262.mp3
    # see #Response::LinkPreview
    GET_MESSAGE_PREVIEW = Action.new 12

    # Get the position of the ears to your Nabaztag.
    # this request is not an action in the Violet
    # API but we do as if it was because it's make
    # more sens (to me).
    # see #Response::EarPositionSend and 
    # #Response::EarPositionNotSend
    # TODO : write doc about that in module desc.
    GET_EARS_POSITION = Action.new nil
    def GET_EARS_POSITION.to_url
      'ears=ok'
    end

    # Send your Rabbit to sleep
    # see #Response::CommandSend
    SET_RABBIT_ASLEEP = Action.new 13

    # Wake up your Rabbit
    # see #Response::CommandSend
    SET_RABBIT_AWAKE = Action.new 14


  end # module Request



  # TODO
  module Response

    # ProtocolExcepion are raised if server
    # return a unknown response.
    # see http://api.nabaztag.com/docs/home.html#messages
    class ProtocolExcepion < Exception; end


    ## Basic class
    # contains some basic stuff, abstract class
    # etc. they're used internaly and you should
    # only use derivated class.
    module Base

      ## abstract class.
      # base class used to handle Violet server's
      # responses
      class ServerRsp
        # String: response message element.
        attr_reader :message
        # String: response comment element.
        attr_reader :comment

        # create a new ServerRsp.
        # parse the given +xml+ to set +comment+
        # and +message+.  must be overrided if
        # self is not a simple server's response.
        # 'simple' mean with only +message+ and
        # +comment+ elements in XML response
        def initialize xml
          require 'rexml/document'
          begin
            @xml = REXML::Document.new xml
          rescue REXML::ParseException => e
            raise ProtocolExcepion.new(e.message)
          end
          @message = @xml.elements['//message'].text
          @comment = @xml.elements['//comment'].text
        end

        # return +true+ if the response is not an
        # error, +false+ otherwhise.
        def good?
          self.is_a? GoodServerRsp
        end

        # return +true+ if the response is an
        # error, +false+ otherwhise.
        def bad?
          self.is_a? BadServerRsp
        end
      end


      ##  handle errors messages
      # All error message are 'simple' : they
      # only have a message and a comment element.
      # so class that inherit of this class have
      # usualy no code.
      # see http://api.nabaztag.com/docs/home.html#messages
      class BadServerRsp < ServerRsp; end


      ## handle messages with infos.
      # good responses contains often infos (like
      # ear position etc) then class that inherit
      # of #GoodServerRsp often define initialize
      # to parse xml and add instances variables.
      class GoodServerRsp < ServerRsp; end

    end # module Response::Base


    #
    # Errors messages from server
    #

    # Too much requests sent
    class AbuseSending < Base::BadServerRsp; end
    # Wrong token or serial number 
    class NoGoodSerialOrToken < Base::BadServerRsp; end
    # Wrong music id (either not in your personal
    # MP3s list or not existing)
    class MessageNotSend < Base::BadServerRsp; end
    #  urlList parameter missing (api_stream)
    class NoCorrectParameters < Base::BadServerRsp; end
    # The rabbit is not a Nabaztag/tag
    class NotV2Rabbit < Base::BadServerRsp; end
    # Nabcast not posted because music id is
    # not part of your personal MP3s or because
    # the nabcast id does not belong to you or is
    # not existing
    class NabCastNotSend < Base::BadServerRsp; end
    # Message not sent
    class MessageNotSend < Base::BadServerRsp; end
    # TTS creation problem or TTS not send
    class TtsNotSend < Base::BadServerRsp; end
    # Choregraphy message not sent because the
    # "chor" command was incorrect
    class ChorNotSend < Base::BadServerRsp; end
    # Ears position not sent because the given
    # position is incorrect
    class EarPositionNotSend < Base::BadServerRsp; end
    # URL was not sent (api_stream)
    class WebRadioNotSend < Base::BadServerRsp; end


    #
    # Infos messages from server
    #

    # Nabcast posted
    class NabCastSend < Base::GoodServerRsp; end
    # Command has been send
    # see Request::SET_RABBIT_ASLEEP and 
    # Request::SET_RABBIT_AWAKE
    class CommandSend < Base::GoodServerRsp; end
    # Message sent
    class MessageSend < Base::GoodServerRsp; end
    # TTS message sent
    class TtsSend < Base::GoodServerRsp; end
    # Choregraphy message sent
    class ChorSend < Base::GoodServerRsp; end
    # Ears position sent
    class EarPositionSend < Base::GoodServerRsp; end
    # URL was sent (api_stream)
    class WebRadioSend < Base::GoodServerRsp; end
    # Preview the TTS or music (with music id)
    # without sending it
    class LinkPreview < Base::GoodServerRsp; end

    # Getting the ears position
    class PositionEar < Base::GoodServerRsp
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
    class FriendList < Base::GoodServerRsp
        # TODO
    end

    # TODO
    class RecivedMsgList < Base::GoodServerRsp
      # TODO
    end

    # TODO
    class NabaTimezone < Base::GoodServerRsp
      # TODO
    end

    # TODO
    class NabaSignature < Base::GoodServerRsp
      # TODO
    end

    # TODO
    class NabaBlacklist < Base::GoodServerRsp
      # TODO
    end

    # TODO
    class RabbitSleep < Base::GoodServerRsp
      # TODO
    end

    # TODO
    class RabbitVersion < Base::GoodServerRsp
      # TODO
    end

    # TODO
    class TtsVoiceList < Base::GoodServerRsp
      # TODO
    end

    # TODO
    class NabName < Base::GoodServerRsp
      # TODO
    end

    # TODO
    class UserLangList < Base::GoodServerRsp
      # TODO
    end

  end # module Response



  # TODO
  module Help
    # TODO
  end

end # VioletAPI

