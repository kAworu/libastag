=begin rdoc
==libastag/helpers.rb
some handy class/methods and modifications.
=end

require 'rexml/document'


module Libastag

  module Helpers


    # REXML::Attributes#to_hash seems to be broken.
    class REXML::Attributes
      if defined?(to_hash)
        alias :to_hash_old :to_hash
      end

      # convert attributes to an instance of Hash.
      def to_hash
        h = Hash.new
        self.each { |key,value| h[key.to_sym] = value }
        return h
      end
    end


    # ==Credits
    #     Copyright (c) 2005 David Heinemeier Hansson
    # taken from active_support/inflector.rb (MIT licence)
    # see http://rubyforge.org/projects/activesupport
    #
    #
    # ==Summary
    # Constantize tries to find a declared constant with the name specified
    # in the string. It raises a NameError when the name is not in CamelCase
    # or is not initialized.
    #
    #
    # ==Examples
    #     Helpers.constantize("Module")   #=> Module
    #     Helpers.constantize("Class")    #=> Class
    def Helpers.constantize(camel_cased_word)
      unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ camel_cased_word
        raise NameError.new("#{camel_cased_word.inspect} is not a valid constant name!")
      end

      Object.module_eval("::#{$1}", __FILE__, __LINE__)
    end


  end # module Helpers

end # module Libastag
