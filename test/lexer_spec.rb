require "lexer"

# code = <<-CODE
# $test_num = 10
# @instance = 4
# method_name do |arg, list|
#   # Comment, shouldn't appear
# end
# CODE

# tokens = [
#   [:CONSTANT, "test_num"], ["=", "="], [:NUMBER, 10],
#   [:INSTANCE_VAR, "instance"], ["=", "="], [:NUMBER, 4],
#   [:IDENTIFIER, "method_name"], [:DO, "do"], ["|", "|"], [:IDENTIFIER, "arg"], [:IDENTIFIER, "list"], ["|", "|"],
#   [:END, "end"]
# ]

describe "EleetScript Lexer" do
  let(:lexer) { EleetScript::Lexer.new }

  describe "variable types" do
    it "should tokenize constants" do
      code = "Constant_name"
      lexer.tokenize(code).should eq([[:CONSTANT, "Constant_name"]])
    end

    it "should tokenize global variables" do
      code = "$global_name"
      lexer.tokenize(code).should eq([[:GLOBAL, "global_name"]])
    end

    it "should tokenize class variables" do
      code = "@@class"
      lexer.tokenize(code).should eq([[:CLASS_VAR, "class"]])
    end

    it "should tokenize instance variables" do
      code = "@instance_var"
      lexer.tokenize(code).should eq([[:INSTANCE_VAR, "instance_var"]])
    end

    it "should tokenize identifiers" do
      code = "identifier"
      lexer.tokenize(code).should eq([[:IDENTIFIER, "identifier"]])
    end

    it "should not get the five mixed up" do
      code = "CONSTANT $global @instance @@class identifier"
      tokens = [[:CONSTANT, "CONSTANT"], [:GLOBAL, "global"], [:INSTANCE_VAR, "instance"], [:CLASS_VAR, "class"], [:IDENTIFIER, "identifier"]]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "whitespace" do
    it "should ignore spaces and tabs" do
      code = "Constant   \t\t  @instance"
      tokens = [[:CONSTANT, "Constant"], [:INSTANCE_VAR, "instance"]]
      lexer.tokenize(code).should eq(tokens)
    end

    it "should mark newline characters as terminators" do
      code = "Con\n@in"
      tokens = [[:CONSTANT, "Con"], [:TERMINATOR, "\n"], [:INSTANCE_VAR, "in"]]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "operators" do
    it "should tokenize them with the operater as the token type and value" do
      code = "+ - / *"
      tokens = [["+", "+"], ["-", "-"], ["/", "/"], ["*", "*"]]
      lexer.tokenize(code).should eq(tokens)
    end

    it "should tokenize operators with other tokens" do
      code = "(Con = @in)"
      tokens = [["(", "("], [:CONSTANT, "Con"], ["=", "="], [:INSTANCE_VAR, "in"], [")", ")"]]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "semicolon" do
    it "should be tokenized as a terminator" do
      code = "CONSTANT; $global"
      tokens = [[:CONSTANT, "CONSTANT"], [:TERMINATOR, ";"], [:GLOBAL, "global"]]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "keywords" do
    it "should tokenize them with their name symbolized as token name and their text as value" do
      code = "do end while if"
      tokens = [[:DO, "do"], [:END, "end"], [:WHILE, "while"], [:IF, "if"]]
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
        [:END, "end"], [:TERMINATOR, "\n"]
      ]
      lexer.tokenize(code).should eq(tokens)
    end
  end

  describe "literals" do
    describe "numbers" do
      it "should tokenize integers as numbers" do
        code = "10"
        lexer.tokenize(code).should eq([[:NUMBER, 10]])
      end

      it "should allow underscore seperation for numbers" do
        lexer.tokenize("100_000").should eq([[:NUMBER, 100000]])
      end

      it "should tokenize floats as floats" do
        code = "10.134"
        lexer.tokenize(code).should eq([[:FLOAT, 10.134]])
      end

      it "should not confuse them" do
        code = "10 1.234"
        lexer.tokenize(code).should eq([[:NUMBER, 10], [:FLOAT, 1.234]])
      end
    end

    describe "strings" do
      it "should properly tokenize strings" do
        code = "\"String Text\""
        lexer.tokenize(code).should eq([[:STRING, "String Text"]])
      end

      it "should properly tokenize strings with escaped quotes" do
        code = "\"String \\\" text\""
        lexer.tokenize(code).should eq([[:STRING, "String \" text"]])
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
          [:IDENTIFIER, "str"], ["=", "="], [:STRING, "strings\ncan\nexist\non\nmultiple\nlines\n"], [:TERMINATOR, "\n"]
        ]
        lexer.tokenize(code).should eq(tokens)
      end
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
        [:GLOBAL, "global"], ["=", "="], [:STRING, "hello"], [:TERMINATOR, "\n"],
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
        [:IDENTIFIER, "greet"], ["(", "("], [:STRING, "World"], [")", ")"], [:TERMINATOR, "\n"]
      ]
      lexer.tokenize(code).should eq(tokens)
    end
  end
end
