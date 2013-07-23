module EleetScript
  class Lexer
    OPERATORS = ["+", "-", "*", "/", "%", "=", "+=", "-=", "*=", "/=", "%=", "**", "**=", "|", "[", "]", "{", "}", "(", ")", ".", ","]
    KEYWORDS = ["do", "end", "class", "load", "if", "while", "namespace", "else", "elsif", "return", "break", "next"]

    TOKEN_RX = {
      identifiers: /\A([a-z][\w\d]*)/,
      constants: /\A([A-Z][\w\d]*)/,
      globals: /\A\$([a-z][\w\d]*)/i,
      class_var: /\A\@\@([a-z][\w\d]*)/i,
      instance_var: /\A\@([a-z][\w\d]*)/i,
      operator: /\A(.)/,
      whitespace: /\A([ \t]+)/,
      terminator: /\A([;\n])/,
      integer: /\A([\d_]+)/,
      float: /\A([\d_]*?\.[\d_]+)/,
      string: /\A\"(.*?)(?<!\\)\"/m
    }

    def tokenize(code)
      tokens = []
      if code.length == 0
        return tokens
      end
      i = 0
      while i < code.length
        chunk = code[i..-1]
        if constant = chunk[TOKEN_RX[:constants]]
          tokens << [:CONSTANT, constant]
          i += constant.length
        elsif global = chunk[TOKEN_RX[:globals]]
          tokens << [:GLOBAL, $1]
          i += global.length
        elsif class_var = chunk[TOKEN_RX[:class_var]]
          tokens << [:CLASS_VAR, $1]
          i += class_var.length
        elsif instance_var = chunk[TOKEN_RX[:instance_var]]
          tokens << [:INSTANCE_VAR, $1]
          i += instance_var.length
        elsif identifier = chunk[TOKEN_RX[:identifiers]]
          if KEYWORDS.include? identifier
            tokens << [identifier.upcase.to_sym, identifier]
          else
            tokens << [:IDENTIFIER, identifier]
          end
          i += identifier.length
        elsif float = chunk[TOKEN_RX[:float]]
          tokens << [:FLOAT, float.to_f]
          i += float.length
        elsif integer = chunk[TOKEN_RX[:integer]]
          tokens << [:NUMBER, integer.to_i]
          i += integer.length
        elsif string = chunk[TOKEN_RX[:string]]
          tokens << [:STRING, $1.gsub('\"', '"')]
          i += string.length
        elsif terminator = chunk[TOKEN_RX[:terminator]]
          tokens << [:TERMINATOR, terminator]
          i += 1
        elsif space = chunk[TOKEN_RX[:whitespace]]
          i += space.length # ignore spaces and tab characters
        elsif operator = chunk[TOKEN_RX[:operator]]
          if OPERATORS.include? operator
            tokens << [operator, operator]
            i += 1
          else
            raise "Unidentified character #{operator} given"
          end
        else
          i += 1
        end
      end
      tokens
    end
  end
end