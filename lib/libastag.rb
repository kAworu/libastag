
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'libastag/response'
require 'libastag/request'


# Handy class/methods to control a Nabastag.
module Libastag
  VERSION = '0.0.3'


  # this class store all attribute of a Nabaztag.
  # it receive events and  retrieve information
  # from your user account or your #Rabbit
  # (see public methods).
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
      @cache  = Hash.new
      @serial = h[:serial].to_s.upcase
      @token  = h[:token].to_i
#     _________                     _________
#    /         \                   /         \
     @right_ear,                    @left_ear          = RabbitEar.new(:right), RabbitEar.new(:left)
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
                     @top_led                           = RabbitLed.new(:top)
#   |                   |                     |
#   |                                         |
#   |                                         |
#   |                                         |
     @right_led,    @middle_led,     @left_led          = RabbitLed.new(:right), RabbitLed.new(:middle), RabbitLed.new(:left)
#   |                                         |
#   |                                         |
#   |                                         |
#   |                                         |
#   |                                         |
#   |                   |                     |
#  /                                           \
                    @bottom_led                         = RabbitLed.new(:bottom)
# -----------------------------------------------
    end


    # FIXME: should have a parameter :S
    # return the ServerRsp. you can access rsp.message and rsp.comment.
    def link_preview
      query!(Request::GET_LINKPREVIEW)
    end

    # return an array of Strings.
    # Examples TODO
    #   ... [ 'toto', 'tata' ]
    def friends
      rsp = query!(Request::GET_FRIENDS_LIST)
      if rsp.listfriend[:nb].to_i.zero?
        Array.new
      else
        rsp.friends.collect { |f| f[:name] }
      end
    end

    # return an Array of Hash, with <tt>:title</tt>, <tt>:date</tt>, <tt>:from</tt> and <tt>:url</tt> keys.
    def inbox
      rsp = query!(Request::GET_INBOX_LIST)
      if rsp.listreceivedmsg[:nb].to_i.zero?
        Array.new
      else
        rsp.msgs
      end
    end

    # return the Rabbit's timezone. persistant.
    def timezone
      @cache[:timezone] ||= query!(Request::GET_TIMEZONE).timezone
    end

    # return the Rabbit's signature. persistant.
    def signature
      @cache[:signature] ||= query!(Request::GET_SIGNATURE).signature
    end

    # return an array of Strings.
    # Examples TODO
    #   ... [ 'toto', 'tata' ]
    def blacklisted
      rsp = query!(Request::GET_BLACKLISTED)
      if rsp.blacklist[:nb].to_i.zero?
        Array.new
      else
        rsp.pseudos.collect { |f| f[:name] }
      end
    end

    # return +true+ if the Rabbit is asleep, +false+ otherwhise.
    def asleep?
      query!(Request::GET_RABBIT_STATUS).rabbitSleep =~ /YES/i
    end

    # return +true+ if the Rabbit is awake, +false+ otherwhise.
    def awake?
      not asleep?
    end

    # return the Rabbit's version ("V2" or "V1"). persistant.
    #
    # see is_a_tag_tag?
    def version
      @cache[:version] ||= query!(Request::GET_RABBIT_VERSION).rabbitVersion
    end

    # return +true+ if the Rabbit is a nabaztag/tag ("V2" Rabbit), +false+ otherwhise.
    def is_a_tag_tag?
      self.version =~ /V2/i
    end

    # return a Hash. persistant.
    # Examples TODO
    #   ... {:fr => "claire22k", :de => "helga22k"}
    def voices
        @cache[:voices] ||= query!(Request::GET_LANG_VOICE).voices.inject(Hash.new) { |h,i| h[i[:lang].to_sym] = i[:command]; h }
    end

    # return the Rabbit name. persistant.
    def name
      @cache[:name] ||= query!(Request::GET_RABBIT_NAME).rabbitName
    end

    # return an array of languages.
    # Examples TODO
    #   ... [ "fr", "us", "uk", "de" ]
    def langs
      @cache[:langs] ||= query!(Request::GET_SELECTED_LANG).myLangs.collect { |l| l[:lang] }
    end

    # FIXME: should have a parameter :S
    def msg_preview
      query!(Request::GET_MESSAGE_PREVIEW)
    end

    # return the ears position
    def ears_position
      query!(Request::GET_EARS_POSITION)
    end
    # send the Rabbit to sleep. return the sever's response.
    def sleep!
      query(Request::SET_RABBIT_ASLEEP)
    end

    # wake up the Rabbit. return the sever's response.
    def wakeup!
      query!(Request::SET_RABBIT_AWAKE)
    end

    # used to send Query, and check the ServerRsp.
    def query event
      Request::Query.new(:token  => @token, :serial => @serial, :event => event).send!
    end
    
    def query! event
      rsp = query event
      # FIXME: convert into raw xml
      raise "bad response : #{rsp.inspect}" unless rsp.good?
      rsp
    end

  end # class Rabbit


  class RabbitLed
    def initialize x
    end
  end
  

  class RabbitEar
    def initialize x
    end
  end
end

