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


  # Basic class
  # contains some basic stuff, abstract class
  # etc. they're used internaly and you should
  # only use derivated class.
  module Base
    require 'rexml/document'

    # abstract class.
    # base class used to handle Violet server's
    # responses
    class ServerRsp
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

      # TODO
      def get_all element
        @xml.root.elements.collect(element) do |e|
          if block_given?
            yield(e)
          else
            e
          end
        end
      end

      # We want to access to all xml elements
      # easily, like the powerful Ruby On Rails
      # find function.
      # Note that if a class that inherit of this
      # one, define a method (let's say message()),
      # you'll not be able anymore to access to
      # message element (method_missing is not
      # called in this case!). In this particular
      # case you can call #ServerRsp#__xmlement__
      # (in fact, that's why __xmlement__ is a 
      # public method.
      #
      # you can access to elements by typing their name (say that r is a ServerRsp) :
      #   r.has_message?    # => true
      #   r.message         # => [ "NOTV2RABBIT" ]
      #   r.comment         # => [ "V2 rabbit can use this action" ]
      #
      #   TODO: rewritte it
      def method_missing name
        name = name.to_s

        t.elements.collect
        root = @xml.root

        if name =~ /has_(.+)?/
          not root.elements[$1].nil?
        else
          if root.elements[name]
            get_all(name)
          else
            raise NameError.new("undefined local variable or method #{name} for #{self.inspect}")
          end
        end
      end

    end


    # handle errors messages
    # All error message are 'simple' : they
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
  class FriendList < Base::GoodServerRsp; end
  # a count and the list of the messages in your inbox
  class RecivedMsgList < Base::GoodServerRsp; end
  # the timezone in which your Nabaztag is set
  class NabaTimezone < Base::GoodServerRsp; end
  # the signature defined for the Nabaztag
  class NabaSignature < Base::GoodServerRsp; end
  # a count and the list of people in your blacklist
  class NabaBlacklist < Base::GoodServerRsp; end
  # to know if the Nabaztag is sleeping
  class RabbitSleep < Base::GoodServerRsp; end
  # to know if the Nabaztag is a Nabaztag (V1) or a Nabaztag/tag (V2)
  class RabbitVersion < Base::GoodServerRsp; end
  # a list of all supported languages/voices for TTS (text to speach) engine
  class TtsVoiceList < Base::GoodServerRsp; end
  # the name of the Nabaztag
  class RabbitName < Base::GoodServerRsp; end
  # Get the languages selected for the Nabaztag
  class UserLangList < Base::GoodServerRsp; end
  # Command has been send
  # see Request::SET_RABBIT_ASLEEP and 
  # Request::SET_RABBIT_AWAKE
  class CommandSend < Base::GoodServerRsp; end


  # parse given xml and return a new ServerRsp
  # from the corresponding class.
  # Violet messages aren't easy to identify,
  # because there is not id to responses. Then we
  # have to do tricky things to handle them.
  # XXX: performances ?
  def Response.parse raw
    tmp = Base::ServerRsp.new raw # ouch ! we shouldn't create ServerRsp instances, but act as if you didn't see ;)
    klass =
    if tmp.has_message? # try to handle simple responses
      klassname = Response.constants.grep(/#{tmp.message.first}/i).first    rescue nil
      Helpers.constantize "#{self}::#{klassname}"                           rescue nil

    # TODO: study more.
    elsif   tmp.has_listfriend?         then FriendList
    elsif   tmp.has_listreceivedmsg?    then RecivedMsgList
    elsif   tmp.has_timezone?           then NabaTimezone
    elsif   tmp.has_signature?          then NabaSignature
    elsif   tmp.has_blacklist?          then NabaBlacklist
    elsif   tmp.has_rabbitSleep?        then RabbitSleep
    elsif   tmp.has_rabbitVersion?      then RabbitVersion
    elsif   tmp.has_voiceListTTS?       then TtsVoiceList
    elsif   tmp.has_rabbitName?         then RabbitName
    elsif   tmp.has_langListUser?       then UserLangList
    else                                nil
    end

    if klass.nil?
      raise ProtocolExcepion.new("unhandled server's response : #{raw}")
    else
      klass.new raw
    end
  end

end # module Response

