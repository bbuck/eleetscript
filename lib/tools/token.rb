# frozen_string_literal: true

require 'set'

module EleetScript
  class Token
    TYPES = Set.new([
      :eof,

      # single character tokens
      :dot,
      :equal,
      :forward_slash,
      :greater,
      :left_brace,
      :left_bracket,
      :left_paren,
      :less,
      :minus,
      :percent,
      :plus,
      :right_brace,
      :right_bracket,
      :right_paren,
      :star,
      :terminator,

      # two/three-character tokens
      :forward_slash_equal,
      :greater_equal,
      :less_equal,
      :minus_equal,
      :percent_equal,
      :plus_equal,
      :star_equal,
      :star_star,
      :star_star_equal,

      # multi-value tokens
      :break,
      :class,
      :do,
      :else,
      :elsif,
      :end,
      :false,
      :float,
      :identifier,
      :if,
      :integer,
      :load,
      :namespace,
      :next,
      :nil,
      :property,
      :return,
      :self,
      :string,
      :super,
      :true,
      :while,
    ])

    attr_reader :type, :literal, :lexeme, :line

    def initialize(type, literal, lexeme, line)
      raise ArgumentError, "'#{type.inspect}' is not a valid token type" unless TYPES.include?(type)
      raise ArgumentError, 'Lexeme must be a string' unless lexeme.is_a?(String)
      raise ArgumentError, 'Line is not a valid line number' unless line.is_a?(Integer) && line >= 1

      @type = type
      @literal = literal
      @lexeme = lexeme
      @line = line
    end

    def ==(o)
      return false unless o.is_a?(Token)

      type == o.type && literal == o.literal && lexeme == o.lexeme && line == o.line
    end

    def to_s
      (literal || lexeme).to_s
    end

    def inspect
      "<#{self.class.name} #{type.inspect} #{literal || lexeme} line#=#{line}>"
    end
  end
end
