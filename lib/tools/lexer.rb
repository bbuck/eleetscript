# frozen_string_literal: true

require 'set'
require 'logger'

require_relative 'token'

module EleetScript
  class LexicalError < RuntimeError; end

  # The Lexer is a tool that will examine a source string and return a set of tokens found in the source
  # string. These tokens are generally meant to be then fed into a Parser to produce something that can
  # then be acted upon. The tokens themselves are more akin to the "parts of speech" of the source
  # material instructing the parser in how they should be joined and/or interpreted.
  #
  # The Lexer will do it's best not to fail out hard, opting instead to log and record any errors that
  # are encountered such that more than just a single error can potentially be addressed before another
  # lexical analysis occurs.
  #
  # And example of what the lexer will do is take in something like `3 + 4.0` and produce
  # [[:integer, 3], [:plus, '+'], [:float, 4.0]]. The parser may determine this is a binary expression
  # and convert it into something that can perform the operation defined in the string.
  # rubocop:disable Metrics/ClassLength
  class Lexer
    # Matches a binary number literal
    BINARY_NUMBER = /\A0b[0-1_]+\z/

    # Matches an octal number literal
    OCTAL_NUMBER = /\A0o[0-7_]+\z/

    # Matches a hexidecimal number literal
    HEXIDECIMAL_NUMBER = /\A0x[0-9a-fA-F_]+\z/

    # Reserved words are normal identifiers that cannot be used or assigned by the user, only usable by
    # the system.
    RESERVED_WORDS = Set.new(['lambda?', 'lambda', 'self', 'arguments', 'defined?']).freeze

    # Keywords are special words in the language with specific meanings associated to each keyword.
    KEYWORDS = Set.new(['do', 'end', 'class', 'load', 'if', 'while', 'namespace', 'else',
                        'elsif', 'return', 'break', 'next', 'true', 'yes', 'on', 'false',
                        'no', 'off', 'nil', 'self', 'property', 'super']).freeze

    attr_reader :source, :tokens, :errors

    # Initialize the Lexer with the source and logger as well as setting some basic default values.
    # @param [String] source the source string containing the code to tokenize
    # @param [(Logger | #error)] logger a logger to write error information to.
    def initialize(source, logger = nil)
      @logger = logger || Logger.new($stdout)
      @source = source
      @analyzed = false
      @tokens = []
      @start = 0
      @current = 0
      @line = 1
      @errors = []
    end

    # Start the source analysis process. This will update the completion status so that if you call this
    # again the source will not be re-analyzed.
    # @return [Array<EleetScript::Token>] the list of tokens found in the source.
    def tokenize
      return tokens if done?

      analyze_source
      emit_token(:eof)

      @analyzed = true
      tokens
    end

    # Report if the lexer completed it's analysis successfully. This method is pointless until #tokenize
    # is complete, otherwise it will always return true. So to note if the lexer completed successfully
    # you must determine if it's #done? and #successful?.
    # @return [Boolean] true if the lexer has completed and no errors were raised, false if
    #   the lexer raised errors.
    def successful?
      errors.empty?
    end

    # Report if the lexer has completed anazlying the source string.
    # @return [Boolean] true if #tokenize hasn't been called yet, false if it's already been
    #   called.
    def done?
      @analyzed
    end

    # Determine if the given word is in the list of keywords.
    # @param [#to_s] word the word in question
    # @return [Boolean] true if the words is a keyword, false if it's not
    def keyword?(word)
      KEYWORDS.include?(word.to_s)
    end

    # Determine if the given word is in the list of reserved words.
    # @param [#to_s] word the word in question
    # @return [Boolean] true if the word is reserved, false if it's not
    def reserved?(word)
      RESERVED_WORDS.include?(word.to_s)
    end

    protected

    # Analyze the source string, looking at each character and determining how to represent it
    # as a token.
    # rubocop:disable Metrics/LineLength, Metrics/AbcSize, Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def analyze_source
      loop do
        begin
          break if at_end?
          @start = @current

          char = advance

          case char
          when '.'
            emit_token(:dot)
          when '('
            emit_token(:left_paren)
          when '{'
            emit_token(:left_bracket)
          when '['
            emit_token(:left_brace)
          when ')'
            emit_token(:right_paren)
          when '}'
            emit_token(:right_bracket)
          when ']'
            emit_token(:right_brace)
          when '='
            emit_token(:equal)
          when '|'
            emit_token(:pipe)
          when '+'
            munch_equal_op(:plus, :plus_equal)
          when '-'
            if match('>')
              emit_token(:arrow)
            else
              munch_equal_op(:minus, :minus_equal)
            end
          when '/'
            munch_equal_op(:forward_slash, :forward_slash_equal)
          when '%'
            munch_equal_op(:percent, :percent_equal)
          when '<'
            munch_equal_op(:less, :less_equal)
          when '>'
            munch_equal_op(:greater, :greater_equal)
          when '*'
            if match('*')
              munch_equal_op(:star_star, :star_star_equal)
            else
              munch_equal_op(:star, :star_equal)
            end
          when /[0-9]/
            munch_number
          when /[a-z_]/i
            munch_identifier
          when '"'
            munch_string
          when '#'
            consume(/[^\n]/)
            advance
            next_line
          # rubocop:disable Lint/EmptyWhen
          when ' ', '\t'
            # empty, we don't tokenize these
            # rubocop:enable Lint/EmptyWhen
          when ';', "\n"
            emit_token(:terminator)
            next_line if current_lexeme == "\n"
          else
            error("Unknown character '#{char}' encountered")
          end
        rescue LexicalError => err
          errors << err
          @logger.error("[LEXER] #{err.message}")
          ignore
        end
      end
    end
    # rubocop:enable Metrics/LineLength, Metrics/AbcSize, Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    # Create a token with the given type and value, setting the lexem to the current lexeme
    # and line number to the current line number.
    # @param [Symbol] type the token type to emit
    # @param [Object] value the literal value represented by the token (if any)
    def emit_token(type, value = nil)
      add_token(type, value, current_lexeme)
      @start = @current
    end

    # Create a token from the values provided recorded at the current line. Unlike #emit_token
    # this method neither resets @start nor does it leverage #current_lexeme. This method is
    # for adding a token in a raw manner.
    # @param [Symbol] type the token type to add
    # @param [Object] value the literal value associated with this token, if any.
    # @param [String] lexeme a string representation for what this value looked like in the
    #   source material where it was found.
    def add_token(type, value, lexeme)
      @tokens << Token.new(type, value, lexeme, @line)
    end

    # Reset start position to the current location effectivly ignoring the current lexeme.
    def ignore
      @start = @current
    end

    # Advance the lexer forward one character and return the character just before the new
    # current position, representing the "current token to examine"
    # @return [String] the character that was 'consumed' by this call
    def advance
      return nil if at_end?

      @current += 1
      source[@current - 1]
    end

    # Peek at the current character which hasn't been advanced over yet.
    # @return [String] the next character that will be consumed after calling
    #   #advance
    def peek
      return nil if at_end?

      source[@current]
    end

    # Check the next character to see if matches any of the given values/expressions
    # and if it does, we advance over the character and return it otherwise we return
    # nil
    # @param [*(String | Regexp)] matchers a set of strings and/or regular expressions
    #   that will be compared to the next character and consume that character if one
    #   of the inputs matches.
    # @return [(String | nil)] the character consumed if a match is found or nil
    def match(*matchers)
      matchers.each do |match|
        if (match.is_a?(Regexp) && peek =~ match) || peek == match
          return advance
        end
      end

      nil
    end

    # Return the current snapshot of source that the lexer has analyzed, for example if
    # we're munching a number current lexeme might look like: '100_021'
    # @return [String] the current slice of source we're looking at
    def current_lexeme
      source[@start...@current]
    end

    # Returns the current lexeme minus an opening and closing quote if they're present in
    # the string.
    # @return [String] the current slice of analyzed source minus an opening and closing quote
    #   that may or may not be present.
    def string_lexeme
      lexeme = current_lexeme

      if lexeme[0] == '"'
        lexeme = lexeme[1..-1]
      end

      if lexeme.end_with?('"') && !lexeme.end_with?('\\"')
        lexeme = lexeme[0..-2]
      end

      lexeme
    end

    # Record the current lexeme value, then match an optional closing '}' (which closes the
    # interpolation). Wrap it up by clearing the current lexeme using `ignore`.
    # @return [String] the lexeme representing the interpolated code
    def interpolation_lexeme
      interpolated = current_lexeme
      match('}')
      # clear out the current lexeme, we're handling a different way
      ignore
      interpolated
    end

    # Reports whether the lexer has reached the end of the source string.
    # @return [Boolean] true if the we're done analyzing the string or false otherwise.
    def at_end?
      @current >= source.length
    end

    # Advance the line number tracker to the next line.
    def next_line
      @line += 1
    end

    # Continue advanced as long as the next character matches an input set of matchers.
    # The matchers are passed directly through to #match.
    # @param [*(String | Regexp)] matchers the matchers to look for before advancing the
    #   lexer.
    def consume(*matchers)
      loop do
        return unless match(*matchers)
      end
    end

    # Create and raise a lexical error containing line number.
    # @param [String] message Is the error message (without location information)
    # @raise [LexicalError] with the message and line number
    def error(message)
      raise LexicalError, "#{message} on line #{@line}"
    end

    # Analyze the provided substring to produce a set of tokens. This essentially creates
    # a new Lexer and forces it's line number before tokenizing. The subtokens are returned.
    # @param [String] substring the small substring (most likely of the source value) that needs
    #   to be tokenized
    # @return [Array<EleetScript::Token>] the tokens generated from the provided substring
    def analyze_substring(substring)
      sub_lexer = Lexer.new(substring)
      sub_lexer.instance_variable_set(:@line, @line)
      sub_lexer.tokenize
    end

    # MUNCHERS

    # Munch an optional following '=' character if one is present.
    # @param [Symbol] type the token type if no equal is present in the source
    # @param [Symbol] equal_type the token type if an equal is present in the source
    def munch_equal_op(type, equal_type)
      if match('=')
        emit_token(equal_type)
      else
        emit_token(type)
      end
    end

    # Munch a number from the source. Number can follow a variety of potential appearances.
    #
    # Integers start with a 1 or great and are followed by any number of numeric characters
    # or underscores (as a separator) like `10`, `18_322`.
    #
    # Floats start with a zero or an integer followed by a period and then more numbers. Also
    # can contain underscore values as a separtor. Like `0.3`, `1_231.083_880`.
    def munch_number
      if current_lexeme == '0'
        if match('.')
          munch_float
        else
          munch_special_number
        end
      else
        consume(/\d/, '_')
        if match('.')
          munch_float
        else
          emit_token(:integer, current_lexeme.delete('_').to_i)
        end
      end
    end

    # Munch the float portion of a number. By this point the period and starting numbers are
    # expected to have already been consumed, so this just looks for the fractional part.
    def munch_float
      consume(/\d/, '_')
      emit_token(:float, current_lexeme.delete('_').to_f)
    end

    # Munch special integer values that represent numbers in different bases,
    # supported bases are binary (`0b`), hex (`0x`), and octal (`0o`). These will be
    # parsed and then converted to base 10 before the token is emitted.
    def munch_special_number
      type = match('b', 'o', 'x')
      case type
      when 'b'
        munch_binary
      when 'o'
        munch_octal
      when 'x'
        munch_hex
      else
        error('0 cannot begin an integer literal')
      end
    end

    # Munch a binary number, which is any number containing 0 or 1 values.
    # We consume anything that's not whitespace so that we can fail on invalid or incorrectly
    # structured base values.
    def munch_binary
      consume(/\S/, '_')
      lexeme = current_lexeme
      error("Invalid binary number '#{lexeme}'") unless lexeme =~ BINARY_NUMBER
      emit_token(:integer, lexeme[2..-1].delete('_').to_i(2))
    end

    # Munch an octal number, which is any number containing 0 - 7 values.
    # We consume anything that's not whitespace so that we can fail on invalid or incorrectly
    # structured base values.
    def munch_octal
      consume(/\S/, '_')
      lexeme = current_lexeme
      error("Invalid octal number '#{lexeme}'") unless lexeme =~ OCTAL_NUMBER
      emit_token(:integer, lexeme[2..-1].delete('_').to_i(8))
    end

    # Munch a hexidecimal number, which is any number containing 0 - 9 or A -F.
    # We consume anything that's not whitespace so that we can fail on invalid or incorrectly
    # structured base values.
    def munch_hex
      consume(/\S/, '_')
      lexeme = current_lexeme
      error("Invalid hexidecimal number '#{lexeme}'") unless lexeme =~ HEXIDECIMAL_NUMBER
      emit_token(:integer, lexeme[2..-1].delete('_').to_i(16))
    end

    # Munch an alpha-numeric identifier that can contain underscores.
    def munch_identifier
      consume(/[a-z]/i, /\d/, '_')
      lexeme = current_lexeme
      if keyword?(lexeme)
        case lexeme
        when 'true', 'on', 'yes'
          emit_token(:true)
        when 'false', 'off', 'no'
          emit_token(:false)
        else
          emit_token(lexeme.to_sym)
        end
      else
        emit_token(:identifier, lexeme)
      end
    end

    # Munch a string value, including injected code
    def munch_string
      loop do
        consume(/[^"%\\]/)
        if match('"')
          emit_token(:string, string_lexeme)
          break
        elsif match('%')
          munch_interpolation
        elsif match('\\')
          advance
        else
          error("Unexpected end of string, was expecting '\"'")
        end
      end
    end

    def munch_interpolation
      # %% is an 'escape' and print %
      return if match('%')

      emit_token(:string, string_lexeme[0..-2])
      var_interpolation = !match('{')
      ignore

      consume(var_interpolation ? /[^\s"]/ : /[^\n\}]/)
      error('Unexpected end of interpolation') if at_end?

      interpolated = interpolation_lexeme
      interpolated_tokens = analyze_substring(interpolated)
      # ditch the eof token
      interpolated_tokens.pop

      add_token(:plus, nil, '+')
      add_token(:left_paren, nil, '(')
      @tokens += interpolated_tokens
      add_token(:right_paren, nil, ')')
      add_token(:plus, nil, '+')
    end
  end
  # rubocop:enable Metrics/ClassLength
end
