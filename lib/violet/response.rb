# violet/response.rb
#
#
# TODO
module Response
  require "helpers.rb"

  # ProtocolExcepion are raised if server
  # return a unknown response.
  # see http://api.nabaztag.com/docs/home.html#messages
  class ProtocolExcepion < Exception; end


  # contains some basic stuff, abstract class
  # etc. they're used internaly and you should
  # not access this module.
  module Base
    require 'rexml/document'

    # abstract class.
    # base class used to handle Violet server's
    # responses
    class ServerRsp
      # It's possible to access the
      # #REXML::Document object, if needed.
      attr_reader :xml

      # create a new ServerRsp.
      # try parse the given raw xml argument.
      def initialize raw
        begin
          @xml = REXML::Document.new raw
        rescue REXML::ParseException => e
          raise ProtocolExcepion.new(e.message)
        end
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

      # get all xml element that match
      # name. You can give a block that take a
      # #REXML::Element in parameter.
      def get_all name
        name = name.to_s
        # REXML::XPath.match(@xml, element).collect do |e|  <= this one is for a recursive search.
        @xml.root.elements.collect(name) do |e|
          if block_given? then yield(e) else e end
        end
      end

      # We want to access to all xml elements
      # easily, like the powerful Ruby On Rails
      # find function.
      # Note that if a class that inherit of this
      # one, define a method (let's say message()),
      # you'll not be able anymore to access to
      # message element (method_missing is not
      # called in this case!). You will have to
      # call #get_all by hand in this case.
      # Examples :
      #     >> rsp = Response.parse('<?xml version="1.0" encoding="UTF-8"?><rsp><blacklist nb="2"/><pseudo name="toto"/><pseudo name="titi"/></rsp>')
      #     => #<Response::Blacklist:0x2acd8c08f2f8 @xml=<UNDEFINED> ... </>>
      #     >> rsp.blacklist
      #     => {"nb"=>"2"}
      #     >> rsp.pseudo
      #     => {"name"=>"toto"}
      #     >> rsp.pseudos
      #     => [{"name"=>"toto"}, {"name"=>"titi"}]
      def method_missing name
        # our method to transforme
        # #REXML::Element into text or hash
        filter = Proc.new do |e|
          e.text || e.attributes.to_hash
        end
        # raise an error when there are no
        # results and method_missing is not
        # a question
        check = Proc.new do |ary|
          if ary.empty?
            raise NameError.new("undefined local variable or method #{$1} for #{self.inspect}")
          else
            ary
          end
        end
        # main case statment
        case name.to_s
        when /^has_(.+)\?$/         then get_all($1).size > 0
        when /^has_many_(.+)s\?$/   then get_all($1).size > 1
        when /(.*)s$/               then check.call( get_all($1).collect(&filter) )
        when /(.*)/                 then check.call( get_all($1).collect(&filter) ).first
        end
      end

    end


    # handle errors messages
    # All error message are 'simple': they
    # only have a message and a comment element.
    # see http://api.nabaztag.com/docs/home.html#messages
    class BadServerRsp < ServerRsp; end


    # handle messages with infos.
    # good responses contains often infos (like
    # ear position etc).
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
  # TODO: complete doc (Request reference)
  #

  # Nabcast posted
  class NabCastSend < Base::GoodServerRsp; end
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
  class PositionEar < Base::GoodServerRsp; end
  # Getting friends list
  class ListFriend < Base::GoodServerRsp; end
  # a count and the list of the messages in your inbox
  class ListReceivedMsg < Base::GoodServerRsp; end
  # the timezone in which your Nabaztag is set
  class Timezone < Base::GoodServerRsp; end
  # the signature defined for the Nabaztag
  class Signature < Base::GoodServerRsp; end
  # a count and the list of people in your blacklist
  class Blacklist < Base::GoodServerRsp; end
  # to know if the Nabaztag is sleeping
  class RabbitSleep < Base::GoodServerRsp; end
  # to know if the Nabaztag is a Nabaztag (V1) or a Nabaztag/tag (V2)
  class RabbitVersion < Base::GoodServerRsp; end
  # a list of all supported languages/voices for TTS (text to speach) engine
  class VoiceListTts < Base::GoodServerRsp; end
  # the name of the Nabaztag
  class RabbitName < Base::GoodServerRsp; end
  # Get the languages selected for the Nabaztag
  class LangListUser < Base::GoodServerRsp; end
  # Command has been send
  # see Request::SET_RABBIT_ASLEEP and 
  # Request::SET_RABBIT_AWAKE
  class CommandSend < Base::GoodServerRsp; end


  # parse given xml and return a new ServerRsp
  # from the corresponding class.
  # Violet messages aren't easy to identify,
  # because there is not id to responses.
  # so if there is an message element, it's a
  # simple response, otherwise we use the first
  # element's name.
  def Response.parse raw
    tmp = Base::ServerRsp.new raw # we shouldn't create ServerRsp instances, but act as if you didn't see ;)
    klass =
    if tmp.has_message? # try to handle simple responses
      klassname = Response.constants.grep(/#{tmp.message.first}/i).first    rescue nil
      Helpers.constantize "#{self}::#{klassname}"                           rescue nil
    elsif   tmp.has_listfriend?         then ListFriend
    elsif   tmp.has_listreceivedmsg?    then ListReceivedMsg
    elsif   tmp.has_timezone?           then Timezone
    elsif   tmp.has_signature?          then Signature
    elsif   tmp.has_blacklist?          then Blacklist
    elsif   tmp.has_rabbitSleep?        then RabbitSleep
    elsif   tmp.has_rabbitVersion?      then RabbitVersion
    elsif   tmp.has_voiceListTTS?       then VoiceListTts
    elsif   tmp.has_rabbitName?         then RabbitName
    elsif   tmp.has_langListUser?       then LangListUser
    else                                nil
    end

    if klass.nil?
      raise ProtocolExcepion.new("unhandled server's response : #{raw}")
    else
      klass.new raw
    end
  end

end # module Response

