=begin rdoc

=violet/response.rb

==Summary
this module handle servers messages. Main method/class are Response.parse and Response::Base::ServerRsp (well documented).

you should only use Response.parse with the server's message (xml) as argument, it returns a ServerRsp instance
from the corresponding class (see all the ServerRsp subclass).  with a ServerRsp instance you can use :

[ r.has_x? ]
  return +true+ if r has at least one element of name "x", return +false+ otherwhise.
[ r.has_many_xs? ]
  return +true+ if r has more than one element of name "x", return +false+ otherwhise.
[ r.x ]
  find the first xml element of name x and return it's text if any, or a hash of it's options
[ r.x ]
  find all xml element of name x and return an Array of their text if any, or their options.
[ r.good? ]
  return +true+ if the response is not an error, +false+ otherwhise.
[ r.bad? ]
  return +true+ if the response is an error, +false+ otherwhise.


==Examples :
    >> rsp = Response.parse('<?xml version="1.0" encoding="UTF-8"?><rsp><blacklist nb="2"/><pseudo name="toto"/><pseudo name="titi"/></rsp>')
    => #<Response::Blacklist:0x2acd8c08f2f8 @xml=<UNDEFINED> ... </>>
    >> rsp.good?
    => true
    >> rsp.has_message?
    => false
    >> rsp.message
    NameError: undefined local variable or method message for #<Response::Blacklist:0x2b1f056afdc0 @xml=<UNDEFINED> ... </>>
    >> rsp.has_blacklist?
    => true
    >> rsp.blacklist
    => {:nb=>"2"}
    >> rsp.pseudo
    => {:name=>"toto"}
    >> rsp.has_many_pseudos?
    => true
    >> rsp.pseudos
    => [{:name=>"toto"}, {:name=>"titi"}]

==Low Level

if you want to access to the REXML::Document object of a ServerRsp you can either use rsp.xml or use ServerRsp#get_all method.

=end

module Response
  require File.join( File.dirname(__FILE__), 'helpers.rb' )

  # ProtocolExcepion are raised if server return a unknown response.
  #
  # see http://api.nabaztag.com/docs/home.html#messages
  class ProtocolExcepion < StandardError; end


  # contains some basic stuff, abstract class etc. they're used internaly and you should not access this module.
  module Base
    require 'rexml/document'

    # base class used to handle Violet server's responses.
    #
    # We want to access to all xml elements easily, like the powerful ActiveRecord 'find' function. This class
    # provide virtual accessor and predicate for elements. If you have a ServerRsp, rsp.has_message? will return
    # +true+ if rsp has a 'message' element, and rsp.has_many_messages? will return +true+ if rsp has more than one
    # 'message' element. rsp.message will return the first message element and rsp.messages will return an Array
    # that contains all message elements of rsp (see doc of Response module for examples).
    class ServerRsp
      # create a ServerRsp with the raw argument. raw must be the xml text of the server's response. if the xml
      # is malformed, a REXML::ParseException will be raised.
      def initialize raw
        @xml = REXML::Document.new raw
      end

      # It's possible to access the REXML::Document object if needed, but try to use virtual accessors and get_all
      # if possible.
      attr_reader :xml

      # return +true+ if the response is not an error, +false+ otherwhise.
      def good?
        self.is_a? GoodServerRsp
      end

      # return +true+ if the response is an error, +false+ otherwhise.
      def bad?
        self.is_a? BadServerRsp
      end

      # ==Summary
      # get all xml's element that match name.
      # 
      #
      # ==Arguments
      # name    : name of the element you want to fetch (see examples)
      # block   : a block of code that take a REXML::Element in parameter. if no block is given, it return an Array of REXML::Element.
      #
      #
      # ==Examples
      # <b>Side effect</b>
      #     >> rsp = Response.parse('<?xml version="1.0" encoding="UTF-8"?><rsp><langListUser nb="4"/><myLang lang="fr"/><myLang lang="us"/><myLang lang="uk"/><myLang lang="de"/></rsp>')
      #     => #<Response::LangListUser:0x2b16c5e17510 @xml=<UNDEFINED> ... </>>
      #     >> rsp.get_all(:myLang) do |e|
      #     >>   puts "you can use '#{e.attribute('lang').value}'"
      #     >> end
      #     you can use 'fr'
      #     you can use 'us'
      #     you can use 'uk'
      #     you can use 'de'
      #     => [nil, nil, nil, nil]
      #
      # <b>usage of returned value</b>
      #     >> langs = rsp.get_all(:myLang) { |e| e.attribute('lang').value }
      #     => ["fr", "us", "uk", "de"]
      def get_all name
        # REXML::XPath.match(@xml, element).collect do |e|  <= this one is for a recursive search.
        @xml.root.elements.collect(name.to_s) do |e|
          if block_given? then yield(e) else e end
        end
      end

      # here some magic code :)
      def method_missing(name) #:nodoc:
        # this method to transforme REXML::Element into text or hash
        filter = Proc.new do |e|
          e.text || e.attributes.to_hash
        end
        # raise an error when there are no results and method_missing is not a question
        check = Proc.new do |ary|
          if ary.empty?
            raise NameError.new("undefined local variable or method #{$1} for #{self.inspect}")
          else
            ary
          end
        end

        case name.to_s
        when /^has_many_(.+)s\?$/   then get_all($1).size > 1
        when /^has_(.+)\?$/         then get_all($1).size > 0
        when /(.*)s$/               then check.call( get_all($1).collect(&filter) )
        when /(.*)/                 then check.call( get_all($1).collect(&filter) ).first
        end
      end

    end


    # superclass of error messages. They're 'simple', they only have a message and a comment element.
    # see http://api.nabaztag.com/docs/home.html#messages
    class BadServerRsp < ServerRsp; end


    # superclass of messages with infos (no error).
    class GoodServerRsp < ServerRsp; end

  end # module Response::Base



  # superclass of messages with no infos.
  class EmptyServerRsp < Base::ServerRsp; end


  #
  # Errors messages from server
  #


  # Too much requests sent
  #     rsp.message     # => "ABUSESENDING"
  #     rsp.comment     # => "Too much message sending,try later"
  class AbuseSending < Base::BadServerRsp; end


  # Wrong token or serial number 
  #     rsp.message     # => "NOGOODTOKENORSERIAL"
  #     rsp.comment     # => "Your token or serial number are not correct !"
  class NoGoodTokenOrSerial < Base::BadServerRsp; end


  # Wrong music id (either not in your personal MP3s list or not existing)
  #     rsp.message     # => "MESSAGENOTSEND"
  #     rsp.comment     # => "Your idmessage is not correct or is private"
  class MessageNotSend < Base::BadServerRsp; end


  # Nabcast not posted because music id is not part of your personal MP3s or because the nabcast id does not belong
  # to you or is not existing
  #     rsp.message     # => "NABCASTNOTSEND"
  #     rsp.comment     # => "Your idmessage is private"
  #
  #     rsp.message     # => "NABCASTNOTSEND"
  #     rsp.comment     # => "Your nabcast id is not correct or is private"
  class NabCastNotSend < Base::BadServerRsp; end


  # Message not sent
  #     rsp.message     # => "MESSAGENOTSEND"
  #     rsp.comment     # => "Your message could not be sent"
  class MessageNotSend < Base::BadServerRsp; end


  # TTS creation problem or TTS not send
  #     rsp.message     # => "TTSNOTSEND"
  #     rsp.comment     # => "Your text could not be sent"
  #                     
  #     rsp.message     # => "TTSNOTSEND"
  #     rsp.comment     # => "Your text could not be sent"
  class TtsNotSend < Base::BadServerRsp; end


  # Choregraphy message not sent because the "chor" command was incorrect
  #     rsp.message     # => "CHORNOTSEND"
  #     rsp.comment     # => "Your chor could not be sent (bad chor)"
  class ChorNotSend < Base::BadServerRsp; end


  # Ears position not sent because the given position is incorrect
  #     rsp.message     # => "EARPOSITIONNOTSEND"
  #     rsp.comment     # => "Your ears command could not be sent"
  class EarPositionNotSend < Base::BadServerRsp; end


  # URL was not sent (api_stream)
  #     rsp.message     # => "WEBRADIONOTSEND"
  #     rsp.comment     # => "Your webradio could not be sent"
  class WebRadioNotSend < Base::BadServerRsp; end


  #  urlList parameter missing (api_stream)
  #     rsp.message     # => "NOCORRECTPARAMETERS"
  #     rsp.comment     # => "Please check urlList parameter !"
  class NoCorrectParameters < Base::BadServerRsp; end


  # The rabbit is not a Nabaztag/tag
  #     rsp.message     # => "NOTV2RABBIT"
  #     rsp.comment     # => "V2 rabbit can use this action"
  class NotV2Rabbit < Base::BadServerRsp; end


  #
  # Infos messages from server
  #


  # Nabcast posted
  #     rsp.message     # => "NABCASTSEND"
  #     rsp.comment     # => "Your nabcast has been sent"
  class NabCastSend < Base::GoodServerRsp; end


  # Message sent
  #     rsp.message     # => "MESSAGESEND"
  #     rsp.comment     # => "Your message has been sent"
  class MessageSend < Base::GoodServerRsp; end


  # TTS message sent
  #     rsp.message     # => "TTSSEND"
  #     rsp.comment     # => "Your text has been sent"
  class TtsSend < Base::GoodServerRsp; end


  # Choregraphy message sent
  #     rsp.message     # => "CHORSEND"
  #     rsp.comment     # => "Your chor has been sent"
  class ChorSend < Base::GoodServerRsp; end


  # Ears position sent
  #     rsp.message     # => "EARPOSITIONSEND"
  #     rsp.comment     # => "Your ears command has been sent"
  class EarPositionSend < Base::GoodServerRsp; end


  # URL was sent (api_stream)
  #     rsp.message     # => "WEBRADIOSEND"
  #     rsp.comment     # => "Your webradio has been sent"
  class WebRadioSend < Base::GoodServerRsp; end


  # Getting the ears position
  #     rsp.message         # => "POSITIONEAR"
  #     rsp.leftposition    # => "8"
  #     rsp.rightposition   # => "10"
  class PositionEar < Base::GoodServerRsp; end


  # Preview the TTS or music (with music id) without sending it
  #     rsp.message     # => "LINKPREVIEW"
  #     rsp.comment     # => "XXXX"
  class LinkPreview < Base::GoodServerRsp; end


  # Getting friends list
  #     rsp.listfriend  # => {:nb=>"2"}
  #     rsp.friends     # => [{:name=>"toto"}, {:name=>"titi"}]
  class ListFriend < Base::GoodServerRsp; end


  # a count and the list of the messages in your inbox
  #     rsp.listreceivedmsg # => {:nb=>"1"}
  #     rsp.msg             # => {:title=>"my message", :date=>"today 11:59", :from=>"toto", :url=>"broad/001/948.mp3"}
  class ListReceivedMsg < Base::GoodServerRsp; end


  # the timezone in which your Nabaztag is set
  #     rsp.timezone    # => "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"
  class Timezone < Base::GoodServerRsp; end


  # the signature defined for the Nabaztag
  #     rsp.signature   # => "i'm Ruby powered !"
  class Signature < Base::GoodServerRsp; end


  # a count and the list of people in your blacklist
  #     rsp.blacklist   # => {:nb=>"2"}
  #     rsp.pseudos     # => [{:name=>"toto"}, {:name=>"tata"}]
  class Blacklist < Base::GoodServerRsp; end


  # to know if the Nabaztag is sleeping
  #     rsp.rabbitSleep     # => "YES"
  class RabbitSleep < Base::GoodServerRsp; end


  # to know if the Nabaztag is a Nabaztag (V1) or a Nabaztag/tag (V2)
  #     rsp.rabbitVersion   # => "V2"
  class RabbitVersion < Base::GoodServerRsp; end


  # a list of all supported languages/voices for TTS (text to speach) engine
  #     rsp.voiceListTTS    # => {:nb=>"2"}
  #     rsp.voices          # => [{:command=>"claire22k", :lang=>"fr"}, {:command=>"helga22k", :lang=>"de"}]
  class VoiceListTts < Base::GoodServerRsp; end


  # the name of the Nabaztag
  #     rsp.rabbitName      # => "nabmaster"
  class RabbitName < Base::GoodServerRsp; end


  # Get the languages selected for the Nabaztag
  #     rsp.langListUser    # => {"nb"=>"4"}
  #     rsp.myLang          # => {:lang=>"fr"}
  #     rsp.myLangs         # => [{:lang=>"fr"}, {:lang=>"us"}, {:lang=>"uk"}, {:lang=>"de"}]
  class LangListUser < Base::GoodServerRsp; end


  # Command has been send.
  #     rsp.message     # => "COMMANDSEND"
  #     rsp.comment     # => "You rabbit will change status"
  #
  # see Request::SET_RABBIT_ASLEEP and Request::SET_RABBIT_AWAKE
  class CommandSend < Base::GoodServerRsp; end


  # ==Summary
  # parse given raw (xml text) and return a new ServerRsp from the corresponding class.
  #
  # Violet messages aren't
  # easy to identify, because there is not id. So we have to study the xml content if there are no message
  # element (easier to detect the response type).
  #
  #
  # ==Arguments
  # the xml response of the Violet Server.
  #
  #
  # ==Exceptions
  # this method raise a ProtocolExcepion if it's fail to detect the
  # kind of the server's response.
  #
  #
  # ==Examples
  #     >> rsp = Response.parse('<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitSleep>YES</rabbitSleep></rsp>')
  #     => #<Response::RabbitSleep:0x2b16c5e476e8 @xml=<UNDEFINED> ... </>>
  #     >> rsp.class
  #     => Response::RabbitSleep
  #
  #     >> rsp = Response.parse('<?xml version="1.0" encoding="UTF-8"?><rsp><rabbitVersion>V1</rabbitVersion></rsp>')
  #     => #<Response::RabbitVersion:0x2b16c5e154b8 @xml=<UNDEFINED> ... </>>
  #     >> rsp.class
  #     => Response::RabbitVersion
  #
  def Response.parse raw
    tmp = Base::ServerRsp.new raw # we shouldn't create ServerRsp instances, but act as if you didn't see ;)
    klassname = if raw =~ %r|<rsp>\s*</rsp>|i
                  'EmptyServerRsp'
                elsif tmp.has_message?
                  /^#{tmp.message}$/i
                else
                  /^#{tmp.xml.root.elements[1].name}$/i # REXML::Elements#[] has index 1-based and not 0-based, so we really fetch the first element's name
                end

    klass = nil
    begin
      klass = Helpers.constantize "#{self}::#{Response.constants.grep(klassname).first}"
      raise if klass.nil?
    rescue
      raise ProtocolExcepion.new("unknown server's response : #{raw}")
    end

    klass.new raw
  end

end # module Response

