
module VioletAPI

  # the VioletAPI url.
  # see http://api.nabaztag.com/docs/home.html#sendevent
  BASE_URL = 'http://api.nabaztag.com/vl/FR/api.jsp?'

  # abstract
  # TODO
  class Event
    def initialize
      raise NotImplementedError
    end
    def to_url
      raise NotImplementedError
    end
  end

  # combine many events
  # TODO
  class EventNode
  end

  # actions are used to retrieve informations about the
  # Nabaztag or the Nabaztag's owners.
  # see http://api.nabaztag.com/docs/home.html#getinfo
  class Action < Event
    
    # create a new #Action with +id+.
    def initialize id
      @id = id
    end

    def to_url
      "&action=#{@id}"
    end
  end

  # Preview the TTS or music (with music id) without sending it
  GET_LINKPREVIEW     = Action.new  1
  # Get a list of your friends
  GET_FRIENDS_LIST    = Action.new  2
  # Get a count and the list of the messages in your inbox
  GET_INBOX_LIST      = Action.new  3
  # Get the timezone in which your Nabaztag is set
  GET_TIMEZONE        = Action.new  4
  # Get the signature defined for the Nabaztag
  GET_SIGNATURE       = Action.new  5
  # Get a count and the list of people in your blacklist
  GET_BLACKLISTED     = Action.new  6
  # Get to know if the Nabaztag is sleeping (YES) or not (NO)
  GET_RABBIT_STATUS   = Action.new  7
  # Get to know if the Nabaztag is a Nabaztag (V1) or a Nabaztag/tag (V2)
  GET_RABBIT_VERSION  = Action.new  8
  # Get a list of all supported languages/voices for TTS (text to speach) engine
  GET_LANG_VOICE      = Action.new  9
  # Get the name of the Nabaztag
  GET_RABBIT_NAME     = Action.new 10
  # Get the languages selected for the Nabaztag
  GET_SELECTED_LANG   = Action.new 11
  # Get a preview of a message. This works only with the urlPlay parameter and URLs like broad/001/076/801/262.mp3
  GET_MESSAGE_PREVIEW = Action.new 12
  # Send your Rabbit to sleep
  SET_RABBIT_ASLEEP   = Action.new 13
  #  Wake up your Rabbit
  SET_RABBIT_AWAKE    = Action.new 14


  # this class is used to "translate" our #Events into URLs.
  # see http://api.nabaztag.com/docs/home.html
  class Query

    # create a new Query with the give +command+, +serial+, and +token+.
    # +serial+ and +token+ parameters should be checked at a higher level.
    def initialize(command, serial, token)
      @command, @serial, @token = command, serial, token
    end

    def to_url
      VioletAPI::BASE_URL + "&token=#{@token}" + "&sn=#{@serial}" + @event.to_url
    end
  end

  def send! query
    require 'open-uri'
    response = open(query.to_url) { |r| r.read }
    parse(response)
  end

  private
  def parse
    # TODO
  end

end

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

