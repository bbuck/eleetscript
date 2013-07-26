module Cuby
  class LexicalError < RuntimeError
    def initialize(char, line)
      @char = char
      @line = line
    end

    def message
      "Unknown character encountered '#{@char}' on line ##{@line}"
    end
  end

  class ParseError < RuntimeError; end
  class ConstantError < ParseError
    def initialize(name)
      @name = name
    end

    def message
      "Value assigned to #{@name} cannot be an expression."
    end
  end
end

CB = Cuby