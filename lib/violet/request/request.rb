=begin rdoc

==violet/request.rb
contains events to send to the server.  Action instances are constants, because they're always the same request,
but other Event derivated class are used to create objects.

=end

module Request
  require File.join( File.dirname(__FILE__), '..', 'response', 'response.rb' )
 # require File.join( File.dirname(__FILE__), '..', 'helpers',  'helpers.rb'  )

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
          raise ArgumentError.new('bad parameters')
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
        @childrens.collect { |e| e.to_url }.sort.join('&')
      end
    end

  end # module Request::Base



  # this class is used to "translate" our Events into URLs.
  # Examples:
  #     TODO
  # see http://api.nabaztag.com/docs/home.html
  class Query
    require 'open-uri'

    # create a new Query object with the give parameters.  +serial+ and +token+ parameters should be checked at
    # a higher level. +event+ parameter is usually an Event object, but you can give any Object that respond to
    # to_url.
    def initialize h
      raise ArgumentError.new('event parameter has no "to_url" method or is empty') unless h[:event] and h[:event].respond_to?(:to_url)
      raise ArgumentError.new('need a :serial') unless h[:serial]
      raise ArgumentError.new('need a :token' ) unless h[:token]

      @event, @serial, @token = h[:event], h[:serial], h[:token]
    end

    # return the complet url: API_URL with the +serial+, +token+ and options.
    def to_url
      "#{API_URL}?" << [ "token=#{@token}", "sn=#{@serial}", @event.to_url ].join('&')
    end

    # send the query to the server. it return a ServerRsp object from the corresponding class, or the raw xml
    # server's response if called with :xml argument.
    # Examples:
    #  q = Query.new :token => "my_token", :serial => "my_serial", :event => GET_RABBIT_NAME # =>  #<Request::Query:0x2aaaaaee10b8 @event=#<Request::Action:0x2b74bb47f828 @id=10>, @token="my_token", @serial="my_serial">
    #  q.send!          # => #<Response::RabbitName:0x2b74b8c38798 @xml=<UNDEFINED> ... </>>
    #  q.send!(:xml)    # => "<?xml version=\"1.0\" encoding=\"UTF-8\"?><rsp><rabbitName>Makoto</rabbitName></rsp>\n"
    #
    def send! response_type=nil
      rsp = open(self.to_url) { |rsp| rsp.read }
      if response_type == :xml then rsp else Response.parse(rsp) end
    end
  end



  class SetEarsPosition < Base::Event
    MIN_POS = 0
    MAX_POS = 16

    def initialize h
      @h = h.dup
      raise ArgumentError.new('at least :posright or :posleft must be set')             unless @h[:posleft] or @h[:posright]
      raise ArgumentError.new(":posright must be between #{MIN_POS} and #{MAX_POS}")    if @h[:posright] and not @h[:posright].to_i.between?(MIN_POS,MAX_POS)
      raise ArgumentError.new(":posleft  must be between #{MIN_POS} and #{MAX_POS}")    if @h[:posleft ] and not @h[:posleft ].to_i.between?(MIN_POS,MAX_POS)
    end

    def to_url
      url = Array.new
      url << "posleft=#{@h[:posleft].to_i}"   if @h[:posleft]
      url << "posright=#{@h[:posright].to_i}" if @h[:posright]
      url.join('&')
    end
  end


  # handle encoding Foo to UTF8 should be done at higher level ?
  class TtsMessage < Base::Event
    require 'cgi'
    MIN_SPEED = 1
    MAX_SPEED = 32000

    MIN_PITCH = 1
    MAX_PITCH = 32000


    def initialize h
      raise ArgumentError.new('no :tts given') unless h[:tts]
      @h = h.dup

      [:speed,:pitch].each do |k|
        min = Helpers.constantize("#{self.class}::MIN_#{k.to_s.upcase}")
        max = Helpers.constantize("#{self.class}::MAX_#{k.to_s.upcase}")

        unless @h[k].to_i.between?(min,max)
          raise ArgumentError.new("#{k} values must be between #{min} and #{max}")
        else
          @h[k] = @h[k].to_i
        end if @h[k]
      end

      # to have a well formatted url
      @h[:tts] = CGI.escape @h[:tts]
    end

    def to_url
      for key,val in @h
        (url ||= Array.new) << "#{key}=#{val}" if val
      end
      url.join('&')
    end
  end


  class IdMessage < Base::Event
    require 'cgi'
    MIN_IDMESSAGE = 0

    def initialize h
      @h = h.dup

      raise ArgumentError.new('no :idmessage given')                unless @h[:idmessage]
      raise ArgumentError.new(":idmessage must be greater than #{MIN_IDMESSAGE}")  unless @h[:idmessage].to_i > MIN_IDMESSAGE

      @h[:idmessage]    = @h[:idmessage].to_i

      @h[:nabcasttitle] = CGI.escape @h[:nabcasttitle] if @h[:nabcasttitle]
      @h[:nabcast]      = @h[:nabcast].to_i if @h[:nabcast]
    end

    def to_url
      url = Array.new
      @h.each_pair do |key,val|
        url << "#{key}=#{val}" if val
      end
      url.join('&')
    end
  end



  # at time 1.2 do
  #   move <right|left|both> [ear[s]] <backward|forward> [of] degrees <0-180>
  #   set <bottom|left|middle|right|top|all> [led[s]] to <red|green|blue|yellow|magenta|cyan|white|rgb([0-255],[0-255],[0-255])>
  # end
  # TODO: evaluation after creation
  class Choregraphy < Base::Event

    class BadChorDesc < Exception; end
    EarCommandStruct = Struct.new :element, :direction, :angle, :time
    LedCommandStruct = Struct.new :element, :color,             :time

    def initialize(*code, &block)
      @code = if block_given? then block else code end
      __choreval__
    end

    def set command
      raise BadChorDesc.new('wrong Choregraphy description')    unless command.is_a?(LedCommandStruct)
      raise BadChorDesc.new('need an element')                  unless command.element
      raise BadChorDesc.new('wrong element')                    unless command.element == :all or command.element.between?(Leds::Positions::BOTTOM,Leds::Positions::TOP)
      raise BadChorDesc.new('need a time')                      unless command.time
      raise BadChorDesc.new('time must be >= than zero')        unless command.time.to_i >= 0
      raise BadChorDesc.new('need a color')                     unless command.color
      raise BadChorDesc.new('wrong size for rgb color array')   unless command.color.size == 3
      command.color.collect! do |c|
        raise BadChorDesc.new('color code must be betwen 0 and 255') unless c.to_i.between?(0,255)
        c.to_i
      end

      template = '%s,led,%s,%s'
      command.color = command.color.join(',')

      if command.element == :all
        (Leds::Positions.constants - ['ALL']).each do |cste_name|
          cste = Helpers.constantize "#{self.class}::Leds::Positions::#{cste_name}"
          @chor << template % [ command.time.to_i, cste, command.color ]
        end
      else
          @chor << template % [ command.time.to_i,  command.element, command.color ]
      end
    end

    def move command
      raise BadChorDesc.new('wrong Choregraphy description')    unless command.is_a?(EarCommandStruct)
      raise BadChorDesc.new('need a time')                      unless command.time
      raise BadChorDesc.new('time must be >= zero')             unless command.time.to_i >= 0
      raise BadChorDesc.new('need an angle')                     unless command.angle
      raise BadChorDesc.new('angle must be between 0 and 180')  unless (0..180).include?(command.angle)
      raise BadChorDesc.new('need a direction')                 unless command.direction
      raise BadChorDesc.new('wrong direction')                  unless command.direction.between?(Ears::Directions::FORWARD,Ears::Directions::BACKWARD)
      raise BadChorDesc.new('need an element')                   unless command.element
      raise BadChorDesc.new('wrong element')                    unless command.element == :both or command.element.between?(Ears::Positions::RIGHT,Ears::Positions::LEFT)

      template = '%s,motor,%s,%s,0,%s'

      if command.element == :both
        # we don't know, maybe your rabbit has more than two ears :)
        (Ears::Positions.constants - ['BOTH']).each do |cste_name|
          cste = Helpers.constantize "#{self.class}::Ears::Positions::#{cste_name}"
          @chor << template % [ command.time.to_i, cste,  command.angle, command.direction ]
        end
      else
        @chor << template % [ command.time.to_i,  command.element, command.angle, command.direction ]
      end
    end

    private

    # String of block evaluator
    def __choreval__
      @chor, @time = Array.new, 0
      
      @code = [@code] unless @code.is_a?(Array)
      @code.each do |code|
        if code.is_a?(Proc)
          instance_eval(&code)
        else
          instance_eval(code.to_s, __FILE__, __LINE__)
        end
      end
    end

    # define dummy methods
    def self.bubble(*methods)
      methods.each do |m|
        define_method(m) { |args| args }
      end
    end

    # set the time and call block if any
    def at time_formated
      @time = time_formated
      yield if block_given?
    end

    # format the time
    def time t
      (10 * t.to_f).round
    end

    # right/left hook, because they must be defined for ears and for leds.
    [:right, :left].each do |m|
      define_method(m) do |arg|
        target = if arg.is_a?(EarCommandStruct) then :ear else :led end
        method("__#{m}_for_#{target}__").call(arg)
      end
    end


    module Leds
      module Colors
        RED     = [255, 0, 0]
        GREEN   = [0, 255, 0]
        BLUE    = [0, 0, 255]
        CYAN    = [0, 255, 255]
        MAGENTA = [255, 0, 255]
        YELLOW  = [255, 255, 0]
        WHITE   = [255, 255, 255]
        OFF     = [  0,   0,   0]
      end
      module Positions
        BOTTOM  = 0
        LEFT    = 1
        MIDDLE  = 2
        RIGHT   = 3
        TOP     = 4
        ALL     = :all
      end
    end

    # leds dummy methods setup
    bubble :led, :leds

    # make possible to write
    #   my_color = [1,2,3]
    #   set all to my_color
    # and also
    #   set all to 1,2,3
    def to *args
      case  i = args.first
      when Array then rgb(*i)
      when LedCommandStruct then i
      else rgb(*args)
      end
    end

    # check values and convert to array
    def rgb(*color)
      command = LedCommandStruct.new
      command.time, command.color  = @time, color
      command
    end

    # generate colors methods
    Leds::Colors.constants.each do |cste_name|
      cste = Helpers.constantize "#{self}::Leds::Colors::#{cste_name}"
      define_method(cste_name.downcase) { rgb(*cste) }
    end

    # generate leds positions methods
    Leds::Positions.constants.each do |cste_name|
      cste = Helpers.constantize "#{self}::Leds::Positions::#{cste_name}"
      # right and left are specials cases
      cste_name = "__#{cste_name}_for_led__" if cste_name =~ /^(LEFT|RIGHT)$/

      define_method(cste_name.downcase) do |command|
        command.element = cste
        command
      end
    end


    module Ears
      module Positions
        RIGHT = 0
        LEFT  = 1
        BOTH  = :both
      end
      module Directions
        FORWARD  = 0
        BACKWARD = 1
      end
    end

    # ears dummy methods setup
    bubble :of, :ear, :ears

    def degrees angle
      angle = angle.to_i
      command = EarCommandStruct.new
      command.angle, command.time = angle, @time
      command
    end

    Ears::Directions.constants.each do |cste_name|
      cste = Helpers.constantize "#{self}::Ears::Directions::#{cste_name}"
      define_method(cste_name.downcase) do |command|
        command.direction = cste
        command
      end
    end

    Ears::Positions.constants.each do |cste_name|
      cste = Helpers.constantize "#{self}::Ears::Positions::#{cste_name}"
      # right and left are specials cases
      cste_name = "__#{cste_name}_for_ear__" if cste_name =~ /^(LEFT|RIGHT)$/

      define_method(cste_name.downcase) do |command|
        command.element = cste
        command
      end
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
  #     Query.new(:event => GET_LINKPREVIEW, :serial => my_serial, :token => my_token).send! # => #<Response::LinkPreview:0x2aaaab100f88 @xml=<UNDEFINED> ... </>>
  # see Response::LinkPreview
  GET_LINKPREVIEW = Action.new 1


  # Get a list of your friends
  # Examples:
  #     Query.new(:event => GET_FRIENDS_LIST, :serial => my_serial, :token => my_token).send!    # => #<Response::ListFriend:0x2af08fd53568 @xml=<UNDEFINED> ... </>>
  # see Response::ListFriend
  GET_FRIENDS_LIST = Action.new 2


  # Get a count and the list of the messages in your inbox
  # Examples:
  #     Query.new(:event => GET_INBOX_LIST, :serial => my_serial, :token => my_token).send!  # => #<Response::ListReceivedMsg:0x2aaaab0e0be8 @xml=<UNDEFINED> ... </>>
  # see Response::ListReceivedMsg
  GET_INBOX_LIST = Action.new 3


  # Get the timezone in which your Nabaztag is set
  # Examples:
  #     Query.new(:event => GET_TIMEZONE, :serial => my_serial, :token => my_token).send!    # => #<Response::Timezone:0x2af091e58f60 @xml=<UNDEFINED> ... </>>
  # see Response::Timezone
  GET_TIMEZONE = Action.new 4
 

  # Get the signature defined for the Nabaztag
  # Examples:
  #     Query.new(:event => GET_SIGNATURE, :serial => my_serial, :token => my_token).send!   # => #<Response::Signature:0x2aaaab0c8c28 @xml=<UNDEFINED> ... </>>
  # see Response::Signature
  GET_SIGNATURE = Action.new 5


  # Get a count and the list of people in your blacklist
  # Examples:
  #     Query.new(:event => GET_BLACKLISTED, :serial => my_serial, :token => my_token).send! # => #<Response::Blacklist:0x2aaaab0b0ad8 @xml=<UNDEFINED> ... </>>
  # see Response::Blacklist
  GET_BLACKLISTED = Action.new 6


  # Get to know if the Nabaztag is sleeping (YES) or not (NO)
  # Examples:
  #     Query.new(:event => GET_RABBIT_STATUS, :serial => my_serial, :token => my_token).send! # => #<Response::RabbitSleep:0x2aaaab092a88 @xml=<UNDEFINED> ... </>>
  # see Response::RabbitSleep
  GET_RABBIT_STATUS = Action.new 7


  # Get to know if the Nabaztag is a Nabaztag (V1) or a Nabaztag/tag (V2)
  # Examples:
  #     Query.new(:event => GET_RABBIT_VERSION, :serial => my_serial, :token => my_token).send!    # => #<Response::RabbitVersion:0x2aaaab07c418 @xml=<UNDEFINED> ... </>>
  # see Response::RabbitVersion
  GET_RABBIT_VERSION = Action.new 8


  # Get a list of all supported languages/voices for TTS (text to speach) engine
  # Examples:
  #         Query.new(:event => GET_LANG_VOICE, :serial => my_serial, :token => my_token).send!    # => #<Response::VoiceListTts:0x2aaaab064368 @xml=<UNDEFINED> ... </>>
  # see Response::VoiceListTts
  GET_LANG_VOICE = Action.new 9


  # Get the name of the Nabaztag
  # Examples:
  #     Query.new(:event => GET_RABBIT_NAME, :serial => my_serial, :token => my_token).send!   # => #<Response::RabbitName:0x2aaaab0459b8 @xml=<UNDEFINED> ... </>>
  # see Response::RabbitName
  GET_RABBIT_NAME = Action.new 10


  # Get the languages selected for the Nabaztag
  # Examples:
  #     Query.new(:event => GET_SELECTED_LANG, :serial => my_serial, :token => my_token).send! # => #<Response::LangListUser:0x2aaaab02bfb8 @xml=<UNDEFINED> ... </>>
  # see Response::LangListUser
  GET_SELECTED_LANG = Action.new 11


  # Get a preview of a message. This works only with the urlPlay parameter and URLs like broad/001/076/801/262.mp3
  # Examples:
  #     Query.new(:event => GET_MESSAGE_PREVIEW, :serial => my_serial, :token => my_token).send!   # => #<Response::LinkPreview:0x2aaaab011258 @xml=<UNDEFINED> ... </>>
  # see Response::LinkPreview
  GET_MESSAGE_PREVIEW = Action.new 12


  # Get the position of the ears to your Nabaztag. this request is not an action in the Violet API but we do as
  # if it was because it's make more sens (to me).
  # Examples:
  #     Query.new(:event => GET_EARS_POSITION, :serial => my_serial, :token => my_token).send! # => #<Response::PositionEar:0x2aaaaaff6908 @xml=<UNDEFINED> ... </>>
  # see Response::PositionEar
  GET_EARS_POSITION = Action.new nil

  def GET_EARS_POSITION.to_url
      'ears=ok'
  end


  # Send your Rabbit to sleep
  # Examples:
  #     Query.new(:event => SET_RABBIT_ASLEEP, :serial => my_serial, :token => my_token).send! # => #<Response::CommandSend:0x2aaaaafbf980 @xml=<UNDEFINED> ... </>>
  # see Response::CommandSend
  SET_RABBIT_ASLEEP = Action.new 13


  # Wake up your Rabbit
  # Examples:
  #     Query.new(:event => SET_RABBIT_AWAKE, :serial => my_serial, :token => my_token).send!  # => #<Response::CommandSend:0x2aaaaafa60c0 @xml=<UNDEFINED> ... </>>
  # see Response::CommandSend
  SET_RABBIT_AWAKE = Action.new 14

end # module Request
