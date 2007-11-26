# lib/violet/helper.rb
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
==violet/helpers.rb
TODO
some handy class/methods and modifications.
=end

module Helpers
  require "rexml/document"


  # REXML::Attributes#to_hash seems to be broken.
  class REXML::Attributes
    if defined? to_hash
      alias :to_hash_old :to_hash
    end

    # convert attributes to an instance of Hash.
    def to_hash
      h = Hash.new
      self.each { |key,value| h[key.to_sym] = value }
      h
    end
  end


  # taken from active_support/inflector.rb,
  # see http://rubyforge.org/projects/activesupport
  #
  # Constantize tries to find a declared constant with the name specified
  # in the string. It raises a NameError when the name is not in CamelCase
  # or is not initialized.
  #     "Module".constantize #=> Module
  #     "Class".constantize #=> Class
  def Helpers.constantize(camel_cased_word)
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ camel_cased_word
      raise NameError.new("#{camel_cased_word.inspect} is not a valid constant name!")
    end

    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end

end

