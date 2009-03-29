
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'libastag/response'
require 'libastag/request'


# Handy class/methods to control a Nabastag.
module Libastag
  VERSION = '0.0.3'


  class RabbitException < StandardError
    attr_reader :server_rsp

    def initialize(msg, server_rsp)
      super msg
      @server_rsp = server_rsp
    end
  end


  # this class store all attribute of a Nabaztag.
  # it receive events and  retrieve information
  # from your user account or your #Rabbit
  # (see public methods).
  # TODO: document persistant
  class Rabbit
    # used to check serial
    SERIAL_MATCHER = /^[0-9A-F]+$/i
    # used to check token
    TOKEN_MATCHER  = /^[0-9]+$/

    #Serial number of the Nabaztag that will receive events
    attr_reader :serial
    # The token is a series of digits given when you activate the Nabaztag receiver.
    # This extra identification limits the risks of spam, since, in order to send 
    # a message, you need to know both the serial number and the toke
    attr_reader :token

    # object that handle left ear, see #RabbitEar.
    attr_reader :left_ear
    # object that handle right ear, see #RabbitEar.
    attr_reader :right_ear
    # object that handle top led, see #RabbitLed.
    attr_reader :top_led
    # object that handle left led, see #RabbitLed.
    attr_reader :left_led
    # object that handle middle led, see #RabbitLed.
    attr_reader :middle_led
    # object that handle right led, see #RabbitLed.
    attr_reader :right_led
    # object that handle bottom led, see #RabbitLed.
    attr_reader :bottom_led


    public
    # create a new Rabbit with given +serial+ and +token+.
    # make a *basic* syntax check of +serial+ and +token+
    # (see #SERIAL_MATCHER and #TOKEN_MATCHER), but it doesn't mean
    # that they are valid.
    def initialize h
      raise ArgumentError.new("bad serial : #{h[:serial]}") unless h[:serial] and h[:serial].to_s =~ SERIAL_MATCHER
      raise ArgumentError.new("bad token  : #{h[:token] }") unless h[:token]  and h[:token].to_s  =~  TOKEN_MATCHER

      led_pos = Request::Choregraphy::Leds::Positions
      ear_pos = Request::Choregraphy::Ears::Positions

      @cache  = Hash.new
      @serial = h[:serial].to_s.upcase
      @token  = h[:token].to_i

#     _________                     _________
#    /         \                   /         \
     @right_ear,                    @left_ear          = RabbitEar.new(self, ear_pos::RIGHT), RabbitEar.new(self, ear_pos::LEFT)
#   |           |                 |           |
#   |           |                 |           |
#   |           |                 |           |
#   |           |                 |           |
#   |           |                 |           |
#   |           |                 |           |
#   |           |                 |           |
#   |           |                 |           |
#   |           |_________________|           |
#   |           |                 |           |
#   |           |                 |           |
#   |                                         |
#   |                                         |
#   |         |                     |         |
#   |                                         |
#   |                  ___                    |
                     @top_led                           = RabbitLed.new(self, led_pos::TOP)
#   |                   |                     |
#   |                                         |
#   |                                         |
#   |                                         |
     @right_led,    @middle_led,     @left_led          = RabbitLed.new(self,led_pos::RIGHT), RabbitLed.new(self,led_pos::MIDDLE), RabbitLed.new(self,led_pos::LEFT)
#   |                                         |
#   |                                         |
#   |                                         |
#   |                                         |
#   |                                         |
#   |                   |                     |
#  /                                           \
                    @bottom_led                         = RabbitLed.new(self,led_pos::BOTTOM)
# -----------------------------------------------
    end

    # used to send Query, return a ServerRsp.
    #
    # =Examples
    #   # send a GET_EARS_POSITION action:
    #   my_rabbit.query Libastag::Request::GET_EARS_POSITION # => => #<Libastag::Response::NoGoodTokenOrSerial:0x2ab23bb9bca8 ...>
    def query event
      Request::Query.new(:token  => @token, :serial => @serial, :event => event).send!
    end
    
    # used to send Query, and check the ServerRsp. It's the "strict" version of query because it raise a
    # RabbitException if server's response is bad.
    #
    # =Examples
    #   # send a GET_EARS_POSITION action:
    #   my_rabbit.query! Libastag::Request::GET_EARS_POSITION
    #   Libastag::RabbitException: bad response : <?xml version="1.0" encoding="UTF-8"?><rsp><message>NOGOODTOKENORSERIAL</message><comment>Your token or serial number are not correct !</comment></rsp>
    #           from libastag.rb:119:in `query!'
    def query! event
      rsp = query(event)
      raise RabbitException.new("bad response : #{rsp.raw}", rsp) unless rsp.good?
      rsp
    end

    # FIXME: should have a parameter :S
    # return the ServerRsp. you can access rsp.message and rsp.comment.
    #
    # =Examples
    # TODO
    def link_preview
      query! Request::GET_LINKPREVIEW
    end

    # return an array of Strings.
    #
    # =Examples
    #   my_rabbit.friends       # => [ "toto", "tata" ]
    #   rabbit_alone.friends    # => []
    def friends
      rsp = query!(Request::GET_FRIENDS_LIST)
      if rsp.listfriend[:nb].to_i.zero?
        Array.new
      else
        rsp.friends.collect { |f| f[:name] }
      end
    end

    # return an Array of Hash, with <tt>:title</tt>, <tt>:date</tt>, <tt>:from</tt> and <tt>:url</tt> keys.
    #
    # =Examples
    #   my_rabbit.inbox # => [{:url=>"broad/926/111/074/10439770.mp3", :from=>"kApin", :date=>"aujourd'hui 00:20:28", :title=>"I'm a sex machine!"}, {:url=>"broad/001/103/813/094/10438606.mp3", :from=>"kApin", :date=>"aujourd'hui 00:02:54", :title=>"Nem"}]
    def inbox
      rsp = query!(Request::GET_INBOX_LIST)
      if rsp.listreceivedmsg[:nb].to_i.zero?
        Array.new
      else
        rsp.msgs
      end
    end

    # return the Rabbit's timezone. persistant.
    #
    # =Examples
    #   my_rabbit.timezone # => "(GMT + 01:00) Bruxelles, Copenhague, Madrid, Paris"
    def timezone
      @cache[:timezone] ||= query!(Request::GET_TIMEZONE).timezone
    end

    # return the Rabbit's signature. persistant.
    # TODO: fix
    def signature
      @cache[:signature] ||= query!(Request::GET_SIGNATURE).signature
    end

    # return an array of Strings.
    #
    # =Examples
    #   my_rabbit.blacklisted # => [ "toto", "tata" ]
    def blacklisted
      rsp = query!(Request::GET_BLACKLISTED)
      if rsp.blacklist[:nb].to_i.zero?
        Array.new
      else
        rsp.pseudos.collect { |f| f[:name] }
      end
    end

    # return +true+ if the Rabbit is asleep, +false+ otherwhise.
    #
    # =Examples
    #   my_rabbit.asleep?  # => false
    def asleep?
      query!(Request::GET_RABBIT_STATUS).rabbitSleep.downcase == 'yes'
    end

    # return +true+ if the Rabbit is awake, +false+ otherwhise.
    #
    # =Examples
    #   my_rabbit.awake?  # => true
    def awake?
      not asleep?
    end

    # return the Rabbit's version ("V2" or "V1"). persistant.
    # see is_a_tag_tag?
    #
    # =Examples
    #   my_rabbit.version  # => "V2"
    def version
      @cache[:version] ||= query!(Request::GET_RABBIT_VERSION).rabbitVersion
    end

    # return +true+ if the Rabbit is a nabaztag/tag ("V2" Rabbit), +false+ otherwhise.
    #
    # =Examples
    #   my_rabbit.is_a_tag_tag?  # => true
    def is_a_tag_tag?
      self.version.downcase == 'v2'
    end

    # return a Hash. persistant.
    #
    # =Examples
    #   my_rabbit.voices
    #   => {:po=>"ester22k", :tu=>"baris22k", :nl=>"femke22k", :pl=>"magda22s", :es=>"maria22k", :os=>"kari22k", :uk=>"kate22k", :us=>"aaron22s", :su=>"matti22k", :da=>"poul22k", :sv=>"ingmar22k", :br=>"paola22k", :fr=>"claire22k", :it=>"chiara22k", :is=>"snorri22k", :de=>"gerhard22k", :fl=>"sofie22k"}
    def voices
        @cache[:voices] ||= query!(Request::GET_LANG_VOICE).voices.inject(Hash.new) { |h,i| h[i[:lang].to_sym] = i[:command]; h }
    end

    # return the Rabbit name. persistant.
    #
    # =Examples
    #   my_rabbit.name # => "Bond, James Bond."
    def name
      @cache[:name] ||= query!(Request::GET_RABBIT_NAME).rabbitName
    end

    # return an array of languages.
    #
    # =Examples
    #   my_rabbit.langs # => ["fr"]
    def langs
      @cache[:langs] ||= query!(Request::GET_SELECTED_LANG).myLangs.collect { |l| l[:lang] }
    end

    # FIXME: should have a parameter :S
    def msg_preview
      query! Request::GET_MESSAGE_PREVIEW
    end

    # return the ears position
    #
    # =Examples
    #   my_rabbit.ears_position # => #<Libastag::Response::PositionEar:0x2b79c5523608 @xml=<UNDEFINED> ... </>, @raw="<?xml version=\"1.0\" encoding=\"UTF-8\"?><rsp><message>POSITIONEAR</message><leftposition>5</leftposition><rightposition>14</rightposition></rsp>\n">
    def ears_position
      query! Request::GET_EARS_POSITION
    end

    # send the Rabbit to sleep. return the sever's response.
    #
    # =Examples
    #   my_rabbit.sleep! # => #<Libastag::Response::CommandSent ...>
    def sleep!
      query! Request::SET_RABBIT_ASLEEP
    end

    # wake up the Rabbit. return the sever's response.
    #
    # =Examples
    #   my_rabbit.wakeup! # => #<Libastag::Response::CommandSent ...>
    def wakeup!
      query! Request::SET_RABBIT_AWAKE
    end

    # interface to TtsMessage. For examples see Request::TtsMessage and Request::TtsMessage.new.
    def say h
      query! Request::TtsMessage.new(h)
    end

    # interface to idMessage/AudioStream
    #
    # =Examples
    # TODO
    def sing *args
      event = if args.first.respond_to?(:has_key?) and args.first.has_key?(:idmessage)
                Request::IdMessage.new(args.first)
              else
                Request::AudioStream.new(args.flatten)
              end

      query! event
    end

    # interface to Choregraphy
    #
    # =Examples
    # TODO
    def dance(h=Hash.new, &block)
      query! Request::Choregraphy.new(h, &block)
    end
  end # class Rabbit


  class RabbitEar
    attr_reader :rabbit, :position

    def initialize(rabbit, position)
      @rabbit, @position = rabbit, position
    end
  end

  class RabbitLed
    attr_reader :rabbit, :position

    def initialize(rabbit, position)
      @rabbit, @position = rabbit, position
    end
  end

end # module Libastag

