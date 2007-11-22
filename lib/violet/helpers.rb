=begin rdoc
==violet/helpers.rb

=end

module Helpers
  require "rexml/document"
  # #REXML::Attributes#to_hash seems to be broken.
  class REXML::Attributes
    if defined? to_hash
      alias :to_hash_old :to_hash
    end

    # convert attributes to an instance of #Hash.
    def to_hash
      self.inject(Hash.new) { |h,key,value| h[key] = value }
    end
  end


  # #REXML::Document#clone seems to be broken.
  class REXML::Document
    if defined? clone
      alias :clone_old :clone
    end

    # make a full copy.
    def clone
      Document.new(self.write.join)
    end
  end


  # taken from active_support/inflector.rb,
  # see http://rubyforge.org/projects/activesupport/
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

