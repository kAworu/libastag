#!/usr/bin/ruby


def from_this_file_path *args
  File.join( File.dirname(__FILE__), *args )
end


require from_this_file_path('..', 'lib', 'violet', 'request.rb' )
require from_this_file_path('..', 'lib', 'violet', 'response.rb')

require 'test/unit'




class RequestBaseTest < Test::Unit::TestCase
  include Request

  class EventTestFake < Base::Event
    # nothin'
  end

  class EventTestSimple < Base::Event
    def initialize str
      @val = str
    end
    def to_url
      @val.to_s
    end
  end

  # make sure that Event is an abstract class and that all class that
  # inherit of Event has to redefine initialize and to_url.
  def test_class_Event
    assert_raise(NotImplementedError) { Base::Event.new }
    assert_raise(NotImplementedError) { EventTestFake.new }

    EventTestFake.class_eval do
      def initialize
      end
    end
    assert_nothing_raised { EventTestFake.new }
    assert_raise(NotImplementedError) { EventTestFake.new.to_url }
  end

  
  def test_EventCollection_new_and_add
    assert_raise(ArgumentError) { Base::EventCollection.new(1,2) }

    class << (s = String.new)
      def to_url
        self
      end
    end
    assert_nothing_raised { Base::EventCollection.new(s,s) }
    assert_nothing_raised { Base::EventCollection.new(EventTestSimple.new(1),EventTestSimple.new(2)) }

    gou = EventTestSimple.new 'gou'
    foo = EventTestSimple.new 'foo'
    assert_equal Base::EventCollection.new(gou,foo).to_url, (gou+foo).to_url
                 
  end


  def test_EventCollection_to_url
    one     = EventTestSimple.new 1
    two     = EventTestSimple.new 2
    three   = EventTestSimple.new 3
    all     = nil

    assert_nothing_raised { all = one + two + three }

    expected_uri = [ one.to_url, two.to_url, three.to_url ]
    assert_equal expected_uri, all.to_url
  end
end
