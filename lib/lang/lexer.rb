require "cuby"

module Cuby
  class Lexer
    KEYWORDS = [
      "do", "end", "class", "load", "if", "while", "namespace", "else", "elsif",
      "return", "break", "next", "true", "yes", "on", "false", "no", "off",
      "nil", "self", "defined?", "property"
    ]

    TOKEN_RX = {
      identifiers: /\A([a-z][\w\d]*[?!]?)/,
      constants: /\A([A-Z][\w\d]*)/,
      globals: /\A(\$[a-z][\w\d]*)/i,
      class_var: /\A(\@\@[a-z][\w\d]*)/i,
      instance_var: /\A(\@[a-z][\w\d]*)/i,
      operator: /\A([+\-\*\/%<>=!]=|\*\*=|\*\*|[+\-\*\/%=><]|or|and|not|\||\(|\)|\[|\]|\{|\}|::|[.,?:])/,
      whitespace: /\A([ \t]+)/,
      terminator: /\A([;\n])/,
      integer: /\A([\d_]+)/,
      float: /\A([\d_]*?\.[\d_]+)/,
      string: /\A\"(.*?)(?<!\\)\"/m,
      comment: /\A#.*?(?:\n|$)/m
    }

    def tokenize(code)
      tokens = []
      if code.length == 0
        return tokens
      end
      line = 1
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
          tokens << [:CLASS_IDENTIFIER, $1]
          i += class_var.length
        elsif instance_var = chunk[TOKEN_RX[:instance_var]]
          tokens << [:INSTANCE_IDENTIFIER, $1]
          i += instance_var.length
        elsif identifier = chunk[TOKEN_RX[:identifiers]]
          if KEYWORDS.include? identifier
            tokens << [identifier.upcase.gsub(/\?\!/, "").to_sym, identifier]
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
        elsif comment = chunk[TOKEN_RX[:comment]]
          i += comment.length # Ignore comments
        elsif terminator = chunk[TOKEN_RX[:terminator]]
          tokens << [:TERMINATOR, terminator]
          if terminator == "\n"
            line += 1
          end
          i += 1
        elsif space = chunk[TOKEN_RX[:whitespace]]
          i += space.length # ignore spaces and tab characters
        elsif operator = chunk[TOKEN_RX[:operator]]
          tokens << [operator, operator]
          i += operator.length
        else
          raise LexicalError.new(code[i], line)
        end
      end
      if tokens.length > 0 && tokens.last != [:TERMINATOR, "\n"]
        tokens << [:TERMINATOR, "\n"]
      end
      tokens << [:EOF, :eof] if tokens.length > 0
      tokens
    end
  end
end