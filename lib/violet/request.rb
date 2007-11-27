=begin rdoc

==violet/request.rb

TODO

contains events to send to the server.  Action instances are constants, because they're always the same request,
but other Event derivated class are used to create objects.

=end

module Request
  require File.join( File.dirname(__FILE__), 'response.rb' )

  # the VioletAPI url where we send request.
  API_URL = 'http://api.nabaztag.com/vl/FR/api.jsp'

  # the VioletAPI url for stream request.
  APISTREAM_URL = 'http://api.nabaztag.com/vl/FR/api_stream.jsp'



  # contains some basic stuff, abstract class etc. they're used internaly and you should only use derivated class.
  module Base

    # superclass of message send to Violet.
    class Event
      # constructor has to be overrided
      def initialize
        raise NotImplementedError
      end

      # it's possible to send multiples events on a single request.
      # Examples:
      #     TODO
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

      # create a new EventCollection with two childrens.
      def initialize one, another
        if one.respond_to?(:to_url) and another.respond_to?(:to_url) # \_o<  Coin !
          @childrens = [ one, another ]
        else
          raise ArgumentError.new("bad parameters")
        end
      end

      # needed by Enumerable module.
      # usage should be obvious :)
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



  # this class is used to "translate" our Events into URLs.
  # Examples:
  #     TODO
  # see http://api.nabaztag.com/docs/home.html
  class Query
    require 'open-uri'
    require 'cgi'

    # create a new Query object with the give parameters.  +serial+ and +token+ parameters should be checked at
    # a higher level.
    def initialize(event, serial, token)
      raise ArgumentError.new("first parameter has no 'to_url' method") unless event.respond_to?(:to_url)
      @event, @serial, @token = event, serial, token
    end

    # return the complet url: API_URL with the +serial+ , +token+ and options.
    def to_url
      API_URL+'?' << [ "token=#{@token}", "sn=#{@serial}", @event.to_url ].join('&')
    end

    # TODO
    def send! response_type=nil
      # rescue ?
      rsp = open(self.to_url) { |rsp| rsp.read }
      if response_type == :xml then rsp else Response.parse(rsp) end
    end
  end



  #
  # Actions list.
  #
  # see http://api.nabaztag.com/docs/home.html#getinfo
  #

  # actions are used to retrieve informations about the Nabaztag or the Nabaztag's owners.
  # see constants of Request module, all Action are Request constant that begin with GET or
  # SET. Request::GET_EARS_POSITION is not an Action in the violet API, but we implement it as it was.
  #
  # see http://api.nabaztag.com/docs/home.html#getinfo
  class Action < Base::Event
    # create a new Action with +id+
    def initialize id
      @id = id
    end

    # Action have only action= option.
    def to_url
        "action=#{@id}"
    end
  end


  # Preview the TTS or music (with music id) without sending it
  # Examples:
  #     Query.new(GET_LINKPREVIEW, my_serial, my_token).send! # => #<Response::LinkPreview:0x2aaaab100f88 @xml=<UNDEFINED> ... </>>
  #
  # see Response::LinkPreview
  GET_LINKPREVIEW = Action.new 1


  # Get a list of your friends
  # Examples:
  #     Query.new(GET_FRIENDS_LIST, my_serial, my_token).send!    # => #<Response::ListFriend:0x2af08fd53568 @xml=<UNDEFINED> ... </>>
  #
  # see Response::ListFriend
  GET_FRIENDS_LIST = Action.new 2


  # Get a count and the list of the messages in your inbox
  # Examples:
  #     Query.new(GET_INBOX_LIST, my_serial, my_token).send!  # => #<Response::ListReceivedMsg:0x2aaaab0e0be8 @xml=<UNDEFINED> ... </>>
  #
  # see Response::ListReceivedMsg
  GET_INBOX_LIST = Action.new 3


  # Get the timezone in which your Nabaztag is set
  # Examples:
  #     Query.new(GET_TIMEZONE, my_serial, my_token).send!    # => #<Response::Timezone:0x2af091e58f60 @xml=<UNDEFINED> ... </>>
  #
  # see Response::Timezone
  GET_TIMEZONE = Action.new 4
 

  # Get the signature defined for the Nabaztag
  # Examples:
  #     Query.new(GET_SIGNATURE, my_serial, my_token).send!   # => #<Response::Signature:0x2aaaab0c8c28 @xml=<UNDEFINED> ... </>>
  #
  # see Response::Signature
  GET_SIGNATURE = Action.new 5


  # Get a count and the list of people in your blacklist
  # Examples:
  #     Query.new(GET_BLACKLISTED, my_serial, my_token).send! # => #<Response::Blacklist:0x2aaaab0b0ad8 @xml=<UNDEFINED> ... </>>
  #
  # see Response::Blacklist
  GET_BLACKLISTED = Action.new 6


  # Get to know if the Nabaztag is sleeping (YES) or not (NO)
  # Examples:
  #     Query.new(GET_RABBIT_STATUS, my_serial, my_token).send! # => #<Response::RabbitSleep:0x2aaaab092a88 @xml=<UNDEFINED> ... </>>
  #
  # see Response::RabbitSleep
  GET_RABBIT_STATUS = Action.new 7


  # Get to know if the Nabaztag is a Nabaztag (V1) or a Nabaztag/tag (V2)
  # Examples:
  #     Query.new(GET_RABBIT_VERSION, my_serial, my_token).send!    # => #<Response::RabbitVersion:0x2aaaab07c418 @xml=<UNDEFINED> ... </>>
  #
  # see Response::RabbitVersion
  GET_RABBIT_VERSION = Action.new 8


  # Get a list of all supported languages/voices for TTS (text to speach) engine
  # Examples:
  #         Query.new(GET_LANG_VOICE, my_serial, my_token).send!    # => #<Response::VoiceListTts:0x2aaaab064368 @xml=<UNDEFINED> ... </>>
  #
  # see Response::VoiceListTts
  GET_LANG_VOICE = Action.new 9


  # Get the name of the Nabaztag
  # Examples:
  #     Query.new(GET_RABBIT_NAME, my_serial, my_token).send!   # => #<Response::RabbitName:0x2aaaab0459b8 @xml=<UNDEFINED> ... </>>
  #
  # see Response::RabbitName
  GET_RABBIT_NAME = Action.new 10


  # Get the languages selected for the Nabaztag
  # Examples:
  #     Query.new(GET_SELECTED_LANG, my_serial, my_token).send! # => #<Response::LangListUser:0x2aaaab02bfb8 @xml=<UNDEFINED> ... </>>
  #
  # see Response::LangListUser
  GET_SELECTED_LANG = Action.new 11


  # Get a preview of a message. This works only with the urlPlay parameter and URLs like broad/001/076/801/262.mp3
  # Examples:
  #     Query.new(GET_MESSAGE_PREVIEW, my_serial, my_token).send!   # => #<Response::LinkPreview:0x2aaaab011258 @xml=<UNDEFINED> ... </>>
  #
  # see Response::LinkPreview
  GET_MESSAGE_PREVIEW = Action.new 12


  # Get the position of the ears to your Nabaztag. this request is not an action in the Violet API but we do as
  # if it was because it's make more sens (to me).
  # Examples:
  #     Query.new(GET_EARS_POSITION, my_serial, my_token).send! # => #<Response::PositionEar:0x2aaaaaff6908 @xml=<UNDEFINED> ... </>>
  #
  # see Response::PositionEar
  GET_EARS_POSITION = Action.new nil

  def GET_EARS_POSITION.to_url
      'ears=ok'
  end


  # Send your Rabbit to sleep
  # Examples:
  #     Query.new(SET_RABBIT_ASLEEP, my_serial, my_token).send! # => #<Response::CommandSend:0x2aaaaafbf980 @xml=<UNDEFINED> ... </>>
  #
  # see Response::CommandSend
  SET_RABBIT_ASLEEP = Action.new 13


  # Wake up your Rabbit
  # Examples:
  #     Query.new(SET_RABBIT_AWAKE, my_serial, my_token).send!  # => #<Response::CommandSend:0x2aaaaafa60c0 @xml=<UNDEFINED> ... </>>
  #
  # see Response::CommandSend
  SET_RABBIT_AWAKE = Action.new 14

end # module Request
