=begin rdoc
==violet/request.rb


contains events to send to the server.  Action
instances are constants, because they're always
the same request, but other Event derivated
class are used to create objects.
=end

module Request

  # the VioletAPI url where we send request.
  # see http://api.nabaztag.com/docs/home.html#sendevent
  API_URL = 'http://api.nabaztag.com/vl/FR/api.jsp?'



  # Basic class
  # contains some basic stuff, abstract class
  # etc. they're used internaly and you should
  # only use derivated class.
  module Base

    # abstract class.
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


    # combine many Event in a single request
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
      # Enumerable module.
      def each
        @childrens.each do |e|
          if e.kind_of? Enumerable
            e.each { |i| yield i }
          else
            yield e
          end
        end
      end

      # override Event#to_url.
      def to_url
        @childrens.collect { |e| e.to_url }.join('&')
      end
    end

  end # module Request::Base



  # this class is used to "translate" our Events
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

    # return the complet url to GET 
    def to_url
      [ API_URL, "token=#{@token}", "sn=#{@serial}", @event.to_url ].join('&')
    end
  end



  #
  # actions list.
  # GET_EARS_POSITION has no +id+ because
  # it's not an action in the Violet API.
  # see http://api.nabaztag.com/docs/home.html#getinfo
  #

  # actions are used to retrieve
  # informations about the Nabaztag
  # or the Nabaztag's owners. see
  # http://api.nabaztag.com/docs/home.html#getinfo
  class Action < Base::Event
    # create a new Action with +id+
    def initialize id
      @id = id
    end

    # override Event#to_url.
    def to_url
        "action=#{@id}"
    end
  end


  # Preview the TTS or music (with music id)
  # without sending it
  # see Response::LinkPreview
  GET_LINKPREVIEW = Action.new 1

  # Get a list of your friends
  # see Response::FriendList
  GET_FRIENDS_LIST = Action.new 2

  # Get a count and the list of the messages
  # in your inbox
  # see Response::RecivedMsgList
  GET_INBOX_LIST = Action.new 3

  # Get the timezone in which your Nabaztag
  # is set
  # see Response::NabaTimezone
  GET_TIMEZONE = Action.new 4

  # Get the signature defined for the Nabaztag
  # see Response::NabaSignature
  GET_SIGNATURE = Action.new 5

  # Get a count and the list of people in
  # your blacklist
  # see Response::NabaBlacklist
  GET_BLACKLISTED = Action.new 6

  # Get to know if the Nabaztag is sleeping
  # (YES) or not (NO)
  # see Response::RabbitSleep
  GET_RABBIT_STATUS = Action.new 7

  # Get to know if the Nabaztag is a Nabaztag
  # (V1) or a Nabaztag/tag (V2)
  # see Response::RabbitVersion
  GET_RABBIT_VERSION = Action.new 8

  # Get a list of all supported
  # languages/voices for TTS (text to speach)
  # engine
  # see Response::TtsVoiceList
  GET_LANG_VOICE = Action.new 9

  # Get the name of the Nabaztag
  # see Response::NabName
  GET_RABBIT_NAME = Action.new 10

  # Get the languages selected for the Nabaztag
  # see Response::UserLangList
  GET_SELECTED_LANG = Action.new 11

  # Get a preview of a message. This works only
  # with the urlPlay parameter and URLs like
  # broad/001/076/801/262.mp3
  # see Response::LinkPreview
  GET_MESSAGE_PREVIEW = Action.new 12

  # Get the position of the ears to your Nabaztag.
  # this request is not an action in the Violet
  # API but we do as if it was because it's make
  # more sens (to me).
  # see Response::EarPositionSend and 
  # Response::EarPositionNotSend
  GET_EARS_POSITION = Action.new nil
  def GET_EARS_POSITION.to_url #:nodoc:
      'ears=ok'
  end

  # Send your Rabbit to sleep
  # see Response::CommandSend
  SET_RABBIT_ASLEEP = Action.new 13

  # Wake up your Rabbit
  # see Response::CommandSend
  SET_RABBIT_AWAKE = Action.new 14


end # module Request
