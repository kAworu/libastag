#!/usr/bin/ruby


def from_this_file_path *args
  File.join( File.dirname(__FILE__), *args )
end


require from_this_file_path('..', 'lib', 'violet', 'helpers', 'helpers.rb')

require 'rexml/document'
require 'test/unit'



class HelpersTest < Test::Unit::TestCase

  def test_attributes_to_hash
    xml = REXML::Document.new '<?xml version="1.0" encoding="UTF-8"?><rsp><listreceivedmsg nb="1"/><msg from="toto" title="my message" date="today 11:59" url="broad/001/948.mp3"/></rsp>'
    xml.root.elements.each('msg') do |e|
      assert_equal({:from => 'toto', :title => 'my message', :date => 'today 11:59', :url => 'broad/001/948.mp3'}, e.attributes.to_hash) 
    end
  end


  CONSTANT_TEST = 42
  def test_constantize
    assert_equal RUBY_VERSION,  Helpers.constantize('RUBY_VERSION')
    assert_equal CONSTANT_TEST, Helpers.constantize("#{self.class}::CONSTANT_TEST")
  end
end
