
require 'violet/violetapi.rb'

# Handy class/methods to control a Nabastag.
module Libastag
  VERSION = '0.0.2'

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
    def initialize serial, token
      raise ArgumentError.new("bad serial : #{serial}") unless serial =~ SERIAL_MATCHER
      raise ArgumentError.new("bad token  : #{token }") unless token  =~  TOKEN_MATCHER
      @serial = serial.upcase
      @token  = token.to_i
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
                    @bottom_led                         = RabbitLed.new :bottom
# -----------------------------------------------
    end


    def name
      # TODO
    end
    def asleep?
      # TODO
    end
    def sleep!
      # TODO
    end
    def awake?
      # TODO
    end
    def wakeup!
      # TODO
    end
    def version
      # TODO
    end
  end


  class RabitLed
  end
  

  class RabitEar
  end
end

