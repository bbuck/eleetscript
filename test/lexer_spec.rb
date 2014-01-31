require "lang/lexer"

describe "EleetScript::Lexer" do
  let(:lexer) { ES::Lexer.new }

  it "should raise LexicalErrors when unknown characters are encountered" do
    code = "^"
    expect {
      lexer.tokenize(code)
    }.to raise_error(ES::LexicalError)
  end

  it "should report line numbers in LexicalErrors" do
    code = "+\n^\n-"
    begin
      lexer.tokenize(code)
    rescue ES::LexicalError => e
      e.message.should eq("Unknown character encountered '^' on line #2")
    end
  end

  describe "variable types" do
    it "should tokenize constants" do
      code = "Constant_name"
      lexer.tokenize(code).should eq([[:CONSTANT, "Constant_name"], [:TERMINATOR, "\n"], [:EOF, :eof]])
    end

    it "should tokenize global variables" do
      code = "$global_name"
      lexer.tokenize(code).should eq([[:GLOBAL, "$global_name"], [:TERMINATOR, "\n"], [:EOF, :eof]])
    end

    it "should tokenize class variables" do
      code = "@@class"
      lexer.tokenize(code).should eq([[:CLASS_IDENTIFIER, "@@class"], [:TERMINATOR, "\n"], [:EOF, :eof]])
    end

    it "should tokenize instance variables" do
      code = "@instance_var"
      lexer.tokenize(code).should eq([[:INSTANCE_IDENTIFIER, "@instance_var"], [:TERMINATOR, "\n"], [:EOF, :eof]])
    end

    describe "identifiers" do
      it "should be tokenized" do
        code = "identifier"
        lexer.tokenize(code).should eq([[:IDENTIFIER, "identifier"], [:TERMINATOR, "\n"], [:EOF, :eof]])
      end

      it "should be allowed to contain ? and ! punctuation" do
        code = "identifier? identifier!"
        lexer.tokenize(code).should eq([[:IDENTIFIER, "identifier?"], [:IDENTIFIER, "identifier!"], [:TERMINATOR, "\n"], [:EOF, :eof]])
      end
    end

    it "should not get the five mixed up" do
      code = "CONSTANT $global @instance @@class identifier"
      tokens = [
        [:CONSTANT, "CONSTANT"], [:GLOBAL, "$global"], [:INSTANCE_IDENTIFIER, "@instance"],
        [:CLASS_IDENTIFIER, "@@class"], [:IDENTIFIER, "identifier"], [:TERMINATOR, "\n"], [:EOF, :eof]
      ]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "whitespace" do
    it "should be ignored if space or tab" do
      code = "Constant   \t\t  @instance"
      tokens = [[:CONSTANT, "Constant"], [:INSTANCE_IDENTIFIER, "@instance"], [:TERMINATOR, "\n"], [:EOF, :eof]]
      lexer.tokenize(code).should eq(tokens)
    end

    it "should be marked terminators if newline" do
      code = "Con\n@in"
      tokens = [[:CONSTANT, "Con"], [:TERMINATOR, "\n"], [:INSTANCE_IDENTIFIER, "@in"], [:TERMINATOR, "\n"], [:EOF, :eof]]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "operators" do
    it "should be tokenized with the operator as the token type and value" do
      operators = ["=>", "->", "+", "-", "*", "/", "%", "=", "+=", "-=", "*=", "/=", "%=", "==", "!=", "**", "**=", "|", "[", "]", "{", "}", "(", ")", ".", ",", "?", ":"]
      code = operators.join(" ")
      tokens = operators.map { |op| [op, op] }.concat [[:TERMINATOR, "\n"], [:EOF, :eof]]
      lexer.tokenize(code).should eq(tokens)
    end

    it "should tokenize operators with other tokens" do
      code = "(Con = @in)"
      tokens = [["(", "("], [:CONSTANT, "Con"], ["=", "="], [:INSTANCE_IDENTIFIER, "@in"], [")", ")"], [:TERMINATOR, "\n"], [:EOF, :eof]]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "semicolon" do
    it "should be tokenized as a terminator" do
      code = "CONSTANT; $global"
      tokens = [[:CONSTANT, "CONSTANT"], [:TERMINATOR, ";"], [:GLOBAL, "$global"], [:TERMINATOR, "\n"], [:EOF, :eof]]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "keywords" do
    it "should tokenize them with their name symbolized as token name and their text as value" do
      code = "do end while if"
      tokens = [[:DO, "do"], [:END, "end"], [:WHILE, "while"], [:IF, "if"], [:TERMINATOR, "\n"], [:EOF, :eof]]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "methods" do
    it "should tokenize methods properly" do
      code = <<-CODE
      method_name do |arg1, arg2|
        var = arg1
      end
      CODE
      tokens = [
        [:IDENTIFIER, "method_name"], [:DO, "do"], ["|", "|"], [:IDENTIFIER, "arg1"], [",", ","], [:IDENTIFIER, "arg2"], ["|", "|"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "var"], ["=", "="], [:IDENTIFIER, "arg1"], [:TERMINATOR, "\n"],
        [:END, "end"], [:TERMINATOR, "\n"], [:EOF, :eof]
      ]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "lambdas" do
    it "should be parsed" do
      code = <<-CODE
      -> { println("Hello, World!") }
      CODE
      tokens = [
        ["->", "->"], ["{", "{"], [:IDENTIFIER, "println"], ["(", "("],
        [:STRING, "Hello, World!"], [")", ")"], ["}", "}"], [:TERMINATOR, "\n"],
        [:EOF, :eof]
      ]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "literals" do
    describe "numbers" do
      it "should tokenize integers as numbers" do
        code = "10"
        lexer.tokenize(code).should eq([[:NUMBER, 10], [:TERMINATOR, "\n"], [:EOF, :eof]])
      end

      it "should allow underscore seperation for numbers" do
        lexer.tokenize("100_000").should eq([[:NUMBER, 100000], [:TERMINATOR, "\n"], [:EOF, :eof]])
      end

      it "should tokenize floats as floats" do
        code = "10.134"
        lexer.tokenize(code).should eq([[:FLOAT, 10.134], [:TERMINATOR, "\n"], [:EOF, :eof]])
      end

      it "should not confuse them" do
        code = "10 1.234"
        lexer.tokenize(code).should eq([[:NUMBER, 10], [:FLOAT, 1.234], [:TERMINATOR, "\n"], [:EOF, :eof]])
      end
    end

    describe "strings" do
      it "should properly tokenize strings" do
        code = "\"String Text\""
        lexer.tokenize(code).should eq([[:STRING, "String Text"], [:TERMINATOR, "\n"], [:EOF, :eof]])
      end

      it "should properly tokenize strings with escaped quotes" do
        code = "\"String \\\" text\""
        lexer.tokenize(code).should eq([[:STRING, "String \" text"], [:TERMINATOR, "\n"], [:EOF, :eof]])
      end

      it "should allow strings to be defined on multiple lines" do
code = <<-CODE
str = "strings
can
exist
on
multiple
lines
"
CODE
        tokens = [
          [:IDENTIFIER, "str"], ["=", "="], [:STRING, "strings\ncan\nexist\non\nmultiple\nlines\n"], [:TERMINATOR, "\n"], [:EOF, :eof]
        ]
        lexer.tokenize(code).should eq(tokens)
      end
    end
  end

  describe "comments" do
    it "should be ignored" do
      code = <<-CODE
      a = 10
      # This is a comment
      b = 20
      CODE
      tokens = [
        [:IDENTIFIER, "a"], ["=", "="], [:NUMBER, 10], [:TERMINATOR, "\n"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "b"], ["=", "="], [:NUMBER, 20], [:TERMINATOR, "\n"],
        [:EOF, :eof]
      ]
      lexer.tokenize(code).should eq(tokens)
    end

    it "should report empty code if just a comment" do
      code = "# Just a comment"
      lexer.tokenize(code).should eq([])
    end
  end

  describe "full programs" do
    it "should correctly tokenize full programs" do
      code = <<-CODE
      CONSTANT = 10
      $global = "hello"
      class Math
        add do |a, b|
          a + b
        end
      end
      math = Math.new
      math.add(10, 20)
      greet do |name|
        print("Hello, %name")
      end
      greet("World")
      CODE
      tokens = [
        [:CONSTANT, "CONSTANT"], ["=", "="], [:NUMBER, 10], [:TERMINATOR, "\n"],
        [:GLOBAL, "$global"], ["=", "="], [:STRING, "hello"], [:TERMINATOR, "\n"],
        [:CLASS, "class"], [:CONSTANT, "Math"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "add"], [:DO, "do"], ["|", "|"], [:IDENTIFIER, "a"], [",", ","], [:IDENTIFIER, "b"], ["|", "|"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "a"], ["+", "+"], [:IDENTIFIER, "b"], [:TERMINATOR, "\n"],
        [:END, "end"], [:TERMINATOR, "\n"],
        [:END, "end"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "math"], ["=", "="], [:CONSTANT, "Math"], [".", "."], [:IDENTIFIER, "new"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "math"], [".", "."], [:IDENTIFIER, "add"], ["(", "("], [:NUMBER, 10], [",", ","], [:NUMBER, 20], [")", ")"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "greet"], [:DO, "do"], ["|", "|"], [:IDENTIFIER, "name"], ["|", "|"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "print"], ["(", "("], [:STRING, "Hello, %name"], [")", ")"], [:TERMINATOR, "\n"],
        [:END, "end"], [:TERMINATOR, "\n"],
        [:IDENTIFIER, "greet"], ["(", "("], [:STRING, "World"], [")", ")"], [:TERMINATOR, "\n"],
        [:EOF, :eof]
      ]
      lexer.tokenize(code).should eq(tokens)
    end
  end
end
