#!/usr/bin/env ruby

require 'libastag'


class String

  MORSE_TABLE = {'a'=> %|.-|,'b'=> %|-...|,'c'=> %|-.-.|,'d'=> %|-..|,'e'=> %|.|,'f'=> %|..-.|,'g'=> %|--.|,'h'=> %|....|,'i'=> %|..|,'j'=> %|.---|,'k'=> %|-.-|,'l'=> %|.-..|,'m'=> %|--|,'n'=> %|-.|,'o'=> %|---|,'p'=> %|.--.|,'q'=> %|--.-|,'r'=> %|.-.|,'s'=> %|...|,'t'=> %|-|,'u'=> %|..-|,'v'=> %|...-|,'w'=> %|.--|,'x'=> %|-..-|,'y'=> %|-.--|,'z'=> %|--..|,'0'=> %|-----|,'1'=> %|.----|,'2'=> %|..---|,'3'=> %|...--|,'4'=> %|....-|,'5'=> %|.....|,'6'=> %|-....|,'7'=> %|--...|,'8'=> %|---..|,'9'=> %|----.| }

  # "translate" a String into Morse code
  def to_morse
    self.downcase.scan(/./).collect do |c|
      MORSE_TABLE[c]
    end.join
  end
end


# time in sec of a dot .
DOT_TIME = 0.1
# time in sec of a dash - (usually 3*DOT_TIME)
DASH_TIME = 3 * DOT_TIME
# time in sec of space between morses . or -
SPACE_TIME = DOT_TIME

# asking user
def ask question
  print question
  gets.chomp
end


def debug
  yield if $DEBUG
end

# get user's name and convert it in morse code
morse = ask("what's your name ? ").to_morse
# get naba's infos

infos = ask('token: '), ask('serial: ')

c = Request::Choregraphy.new do
  # initialize the timer
  timer = 0

  # each dot or dash
  morse.scan(/./).each do |m|
    # choose the good duration time
    time_to_display = if m == '.' then DOT_TIME else DASH_TIME end
    # choose colors at random :)
    random_colors = [rand(255), rand(255), rand(255)]

    at time timer
      set top led to random_colors

    at time (timer + time_to_display)
      set top led off

    timer = timer + time_to_display + SPACE_TIME
  end
end

q = Request::Query.new  :token  => infos.first,
                        :serial => infos.last,
                        :event  => c

rsp = q.send!
debug { puts rsp }

puts (rsp.good? ? 'OK ! sended !' : 'Woaw. pas glop.')
