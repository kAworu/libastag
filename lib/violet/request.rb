# lib/violet/request.rb
#
# Copyright (c) 2007 Perrin Alexandre
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#


=begin rdoc
==request.rb

TODO

contains events to send to the server.  Action instances are constants, because they're always the same request,
but other Event derivated class are used to create objects.
=end

module Request
  require File.join( File.dirname(__FILE__), 'response.rb' )

  # the VioletAPI url where we send request.
  #
  # see http://api.nabaztag.com/docs/home.html#sendevent
  API_URL = 'http://api.nabaztag.com/vl/FR/api.jsp?'



  # contains some basic stuff, abstract class etc. they're used internaly and you should only use derivated class.
  module Base #:nodoc:

    # superclass of message send to Violet should inherit of this class.
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
        if one.respond_to?(:to_url) and another.respond_to?(:to_url) # Coin Coin ! >°_/
          @childrens = [ one, another ]
        else
          raise ArgumentError.new("bad parameters")
        end
      end

      # needed by Enumerable module.
      # usage should be ovious :)
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

    # create a new Query object with the give parameters.  +serial+ and +token+ parameters should be checked at
    # a higher level.
    def initialize(event, serial, token)
      @event, @serial, @token = event, serial, token
    end

    # return the complet url: API_URL with the +serial+ , +token+ and options.
    def to_url
      [ API_URL, "token=#{@token}", "sn=#{@serial}", @event.to_url ].join('&')
    end

    # TODO
    def send! response_type=nil
      # rescue ?
      rsp = open(self.to_url) { |srv| srv.read }
      if response_type == :xml then rsp else Response.parse(rsp) end
    end
  end



  #
  # Actions list.
  # GET_EARS_POSITION has no +id+ because it's not an action in the Violet API.
  #
  # see http://api.nabaztag.com/docs/home.html#getinfo
  #

  # actions are used to retrieve informations about the Nabaztag or the Nabaztag's owners.
  #
  # see http://api.nabaztag.com/docs/home.html#getinfo
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


  # Preview the TTS or music (with music id) without sending it
  # Examples:
  #     TODO
  # see Response::LinkPreview
  GET_LINKPREVIEW = Action.new 1


  # Get a list of your friends
  # Examples:
  #     TODO
  # see Response::FriendList
  GET_FRIENDS_LIST = Action.new 2


  # Get a count and the list of the messages in your inbox
  # Examples:
  #     TODO
  # see Response::RecivedMsgList
  GET_INBOX_LIST = Action.new 3


  # Get the timezone in which your Nabaztag is set
  # Examples:
  #     TODO
  # see Response::NabaTimezone
  GET_TIMEZONE = Action.new 4
 

  # Get the signature defined for the Nabaztag
  # Examples:
  #     TODO
  # see Response::NabaSignature
  GET_SIGNATURE = Action.new 5


  # Get a count and the list of people in your blacklist
  # Examples:
  #     TODO
  # see Response::NabaBlacklist
  GET_BLACKLISTED = Action.new 6


  # Get to know if the Nabaztag is sleeping (YES) or not (NO)
  # Examples:
  #     TODO
  # see Response::RabbitSleep
  GET_RABBIT_STATUS = Action.new 7


  # Get to know if the Nabaztag is a Nabaztag (V1) or a Nabaztag/tag (V2)
  # Examples:
  #     TODO
  # see Response::RabbitVersion
  GET_RABBIT_VERSION = Action.new 8


  # Get a list of all supported languages/voices for TTS (text to speach) engine
  # Examples:
  #     TODO
  # see Response::TtsVoiceList
  GET_LANG_VOICE = Action.new 9


  # Get the name of the Nabaztag
  # Examples:
  #     TODO
  # see Response::NabName
  GET_RABBIT_NAME = Action.new 10


  # Get the languages selected for the Nabaztag
  # Examples:
  #     TODO
  # see Response::UserLangList
  GET_SELECTED_LANG = Action.new 11


  # Get a preview of a message. This works only with the urlPlay parameter and URLs like broad/001/076/801/262.mp3
  # Examples:
  #     TODO
  # see Response::LinkPreview
  GET_MESSAGE_PREVIEW = Action.new 12


  # Get the position of the ears to your Nabaztag. this request is not an action in the Violet API but we do as
  # if it was because it's make more sens (to me).
  # Examples:
  #     TODO
  # see Response::EarPositionSend and Response::EarPositionNotSend
  GET_EARS_POSITION = Action.new nil

  # :nodoc:
  def GET_EARS_POSITION.to_url
      'ears=ok'
  end


  # Send your Rabbit to sleep
  # Examples:
  #     TODO
  # see Response::CommandSend
  SET_RABBIT_ASLEEP = Action.new 13


  # Wake up your Rabbit
  # Examples:
  #     TODO
  # see Response::CommandSend
  SET_RABBIT_AWAKE = Action.new 14

end # module Request
