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

