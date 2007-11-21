# violet/response.rb
#
#
# TODO
module Response

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

      # We want to access to all xml elements easily, like the powerful Ruby On Rails find function.
      # you can access to elements by typing their name (say that r is a ServerRsp) :
      #   r.message   # => [ "NOTV2RABBIT" ]
      #   r.comment   # => [ "V2 rabbit can use this action" ]
      #   TODO: handle messages like action=11
      def method_missing(name)
        ename = "/rsp/#{name}"

        if @xml.elements[ename]
          REXML::XPath.match(@xml, ename).collect { |e| e.text }
        else
          raise NameError.new("undefined local variable or method #{name} for #{self.inspect}") if result.empty?
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
  class NabName < Base::GoodServerRsp; end
  # Get the languages selected for the Nabaztag
  class UserLangList < Base::GoodServerRsp; end
  # Command has been send
  # see Request::SET_RABBIT_ASLEEP and 
  # Request::SET_RABBIT_AWAKE
  class CommandSend < Base::GoodServerRsp; end


  # parse given xml and return a new ServerRsp
  # from the corresponding class.
  def parse xml
    # TODO
  end


end # module Response

