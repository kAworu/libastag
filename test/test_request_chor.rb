#!/usr/bin/ruby


def from_this_file_path *args
  File.join( File.dirname(__FILE__), *args )
end


require from_this_file_path('..', 'lib', 'violet', 'request',  'request.rb' )
require from_this_file_path('..', 'lib', 'violet', 'response', 'response.rb')

require 'test/unit'




class ChorTrinity < Struct.new :code, :strcode, :result
end

class ChoregraphyTest < Test::Unit::TestCase
  include Request

  SIMPLES_CHORS = [
    ChorTrinity.new(Proc.new { set top led red },
                    'set top led red',
                    'chor=10,0,led,4,255,0,0'),
    ChorTrinity.new(Proc.new { move right ear forward of degrees 10 },
                    'move right ear forward of degrees 10',
                    'chor=10,0,motor,0,10,0,0')
  ]

  ALL_CHORS = SIMPLES_CHORS


  def test_creating_simple_choregraphy
    SIMPLES_CHORS.each do |chor|
      assert_equal [chor.result], Choregraphy.new(&chor.code).to_url
      assert_equal [chor.result, 'chortitle=foo'], Choregraphy.new({:name => :foo},&chor.code).to_url
    end
  end


  def test_protected_and_private_methods
    c = Choregraphy.new
    %w[chor __choreval__ at time right left both all top bottom middle led leds ear ears to rgb red green blue cyan magenta yellow white off forward backward of degrees].each do |sym|
      assert_raise(NoMethodError) { eval "c.#{sym}" }
    end
  end


  def test_creating_with_strings
    ALL_CHORS.each do |chor|
      assert_equal Choregraphy.new(&chor.code), Choregraphy.new(:code => chor.strcode)
    end
  end


  def test_creating_with_multiple_args
    chors = ALL_CHORS.collect { |c| c.strcode }
    assert_equal Choregraphy.new(:code => chors), Choregraphy.new(:code => chors.join("\n"))
  end


  def test_at_time_syntax
    ary = Array.new
    ary << Choregraphy.new do
      at time 0
        set right led to green
      at time 1
        set left  led to red
    end
    ary << Choregraphy.new do
      at time 0 do set right led to green   end
      at time 1 do set left  led to red     end
    end
    ary << Choregraphy.new do
      set right led to green at time 0
      set left  led to red   at time 1
    end

    element = ary.pop
    ary.each { |e| assert_equal element, e }
  end


  def test_move_syntax
    ary = Array.new
    ary << Choregraphy.new { move both ears forward degrees 130 }
    ary << Choregraphy.new { move both forward degrees 130 }
    ary << Choregraphy.new { move both forward of degrees 130 }
    ary << Choregraphy.new { move both ears forward of degrees 130 }
    ary << Choregraphy.new { move left  ear forward of degrees 130
                             move right ear forward of degrees 130 }

    element = ary.pop
    ary.each { |e| assert_equal element, e }
  end

  
  def test_set_syntax
    ary = Array.new
    ary << Choregraphy.new {  set left  led green
                              set right led green }
    ary << Choregraphy.new { set left right led to green }
    ary << Choregraphy.new { set right left rgb(0,255,0) }
    ary << Choregraphy.new { set right left to 0,255,0 }

    element = ary.pop
    ary.each { |e| assert_equal element, e }
  end


  def test_operators
    one     = Choregraphy.new { move left ear forward of degrees 42 }
    two     = Choregraphy.new { move right ear forward of degrees 42 }
    onetwo  = Choregraphy.new { move both ears forward of degrees 42 }

    assert_equal one | two, one + two
    assert_equal one & two, Choregraphy.new
    assert_equal one - two, one
    assert_equal two - one, two
    assert_equal onetwo, one + two
    assert_equal onetwo & two, two
    assert_equal onetwo & one, one
    assert_equal onetwo - two, one
    assert_equal onetwo - one, two
    assert_equal onetwo | two, onetwo
    assert_equal onetwo | one, onetwo
  end


  def test_low_level_EarCommandStruct
    expected = Choregraphy.new { at time 0 do move left ear forward of degrees 120 end }

    e = Choregraphy::EarCommandStruct.new
    e.element   = Choregraphy::Ears::Positions::LEFT
    e.direction = Choregraphy::Ears::Directions::FORWARD
    e.angle     = 120
    e.time      = 0 * 10
    
    c = Choregraphy.new
    c.move(e)
    assert_equal expected, c
  end


  def test_low_level_LedCommandStruct
    expected = Choregraphy.new { at time 2 do set right top red end }

    l = Choregraphy::LedCommandStruct.new
    l.elements  = [ Choregraphy::Leds::Positions::RIGHT,
                    Choregraphy::Leds::Positions::TOP ]
    l.color     = Choregraphy::Leds::Colors::RED
    l.time      = 2 * 10
    
    c = Choregraphy.new
    c.set(l)
    assert_equal expected, c
  end
end
