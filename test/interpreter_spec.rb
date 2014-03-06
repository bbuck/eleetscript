require "lang/interpreter"

describe "EleetScript::Interpreter" do
  let(:interpreter) { ES::Interpreter.new }

  describe "simple cases" do
    before(:each) do
      $stdout.should_receive(:puts).with("Hello, World")
    end

    describe "general" do
      it "should interpret simple code" do
        code = "println(\"Hello, World\")"
        interpreter.eval(code)
      end
    end

    describe "variables" do
      it "should handle assigning and reading local variables" do
        code = <<-CODE
        msg = "Hello, World"
        println(msg)
        CODE
        interpreter.eval(code)
      end

      it "should call local methods if local vars aren't defined" do
        code = <<-CODE
        msg do
          "Hello, World"
        end
        println(msg)
        CODE
        interpreter.eval(code)
      end

      it "should handle assigning and reading constants" do
        code = <<-CODE
        Constant = "Hello, World"
        println(Constant)
        CODE
        interpreter.eval(code)
      end

      it "should not accept reassignments to Constants (silently fail)" do
        code = <<-CODE
        Constant = "Hello, World"
        Constant = "Something, Else"
        println(Constant)
        CODE
        ->{ interpreter.eval(code) }.should_not raise_error
      end

      it "should consider nil a valid assignment to a constant" do
        code = <<-CODE
        Message = nil
        Message = "Something Else"
        println("Hello, World") # For the sake of passing the first test
        println(Errors.length)
        CODE
        $stdout.should_receive(:puts).with("1")
        -> { interpreter.eval(code) }.should_not raise_error
      end

      it "should allow assignment of global variables" do
        code = <<-CODE
        $global = "Hello, World"
        println($global)
        CODE
        -> { interpreter.eval(code) }.should_not raise_error
      end
    end
  end

  describe "global variables" do
    it "should be accessible in multiple scopes" do
      code = <<-CODE
      $global = "Hello, World"
      test_method do
        println($global)
      end
      test_method
      println($global)
      CODE
      $stdout.should_receive(:puts).twice.with("Hello, World")
      interpreter.eval(code)
    end
  end

  describe "strings" do
    it "should work normally" do
      code = "println(\"Hello\")"
      $stdout.should_receive(:puts).with("Hello")
      interpreter.eval(code)
    end

    it "should interpolate variables" do
      code = <<-CODE
      a = "Hello"
      println("%a")
      CODE
      $stdout.should_receive(:puts).with("Hello")
      interpreter.eval(code)
    end

    it "should not interpolate escaped sequences" do
      code = <<-CODE
      a = "Hello"
      println("\\%a")
      CODE
      $stdout.should_receive(:puts).with("%a")
      interpreter.eval(code)
    end

    it "should allow percent signs in strings" do
      code = "println(\"10%\")"
      $stdout.should_receive(:puts).with("10%")
      interpreter.eval(code)
    end

    it "should have a * function" do
      code = <<-CODE
      a = "Hello"
      println(a * 3)
      CODE
      $stdout.should_receive(:puts).with("HelloHelloHello")
      interpreter.eval(code)
    end
  end

  describe "regular expressions" do
    it "should work normally" do
      code = "println(r\"[a-z]\")"
      $stdout.should_receive(:puts).with("r\"[a-z]\"")
      interpreter.eval(code)
    end

    it "should allow matches to happen" do
      code = <<-ES
      if "Brandon" =~ r"[A-Z][a-z]+"
        println("Yes")
      else
        println("No")
      end
      ES
      $stdout.should_receive(:puts).with("Yes")
      interpreter.eval(code)
    end
  end

  describe "numbers" do
    it "should allow negative" do
      code = "println(-10)"
      $stdout.should_receive(:puts).with("-10")
      interpreter.eval(code)
    end

    it "should do math on negative numbers" do
      code = "println(-10 + 8)"
      $stdout.should_receive(:puts).with("-2")
      interpreter.eval(code)
    end
  end

  describe "methods" do
    it "should receive compiled arguments" do
      code = <<-CODE
      test do |a|
        println(a)
        println(arguments)
      end
      test("Hello", "World")
      CODE
      $stdout.should_receive(:puts).with("Hello")
      $stdout.should_receive(:puts).with("[\"Hello\", \"World\"]")
      interpreter.eval(code)
    end

    it "should be usable wihtout specific params" do
      code = <<-CODE
      add do
        arguments[0] + arguments[1]
      end
      println(add(1, 2))
      CODE
      $stdout.should_receive(:puts).with("3")
      interpreter.eval(code)
    end

    it "should interpret .= operators" do
      code = <<-CODE
      str = "Hello, World!"
      str .= substr(0, -2)
      println(str)
      CODE
      $stdout.should_receive(:puts).with("Hello, World")
      interpreter.eval(code)
    end
  end

  describe "classes" do
    it "should interpret class definitions" do
      code = <<-CODE
      class Greeter
        init do |@greeting| end
        greet do |name|
          "%@greeting %name"
        end
      end
      CODE
      ->{ interpreter.eval(code) }.should_not raise_error
    end

    it "should be usable" do
      code = <<-CODE
      class Sample
        msg do "Hello, World" end
      end
      println(Sample.new.msg)
      CODE
      $stdout.should_receive(:puts).with("Hello, World")
      interpreter.eval(code)
    end

    it "should interpret the Greeter sample" do
      code = <<-CODE
      class Greeter
        init do |@greeting| end
        greet do |name|
          println("%@greeting, %name")
        end
      end
      g = Greeter.new("Hello")
      g.greet("World")
      g2 = Greeter.new("Hola")
      g2.greet("Mundo")
      g.greet("Fran")
      CODE
      $stdout.should_receive(:puts).with("Hello, World")
      $stdout.should_receive(:puts).with("Hola, Mundo")
      $stdout.should_receive(:puts).with("Hello, Fran")
      interpreter.eval(code)
    end

    it "should allow class method definition" do
      code = <<-CODE
      class Greeter
        @@create do |greeting|
          Greeter.new(greeting)
        end
        init do |@greeting| end
        greet do |name|
          println("%@greeting, %name")
        end
      end
      g = Greeter.create("Hello")
      g.greet("World")
      CODE
      $stdout.should_receive(:puts).with("Hello, World")
      interpreter.eval(code)
    end

    it "should interpret with namespace qualifiers" do
      code = <<-CODE
      namespace Test end
      class Test::MyObject
        test do println("Hello, World") end
      end
      Test::MyObject.new.test
      CODE
      $stdout.should_receive(:puts).with("Hello, World")
      -> { interpreter.eval(code) }.should_not raise_error
    end
  end

  describe "if statements" do
    it "should have functional if statements" do
      code = <<-CODE
      if true
        println("yes")
      end
      if yes
        println("yes")
      end
      if on
        println("yes")
      end
      CODE
      $stdout.should_receive(:puts).with("yes").exactly(3)
      interpreter.eval(code)
    end

    it "should be truthy" do
      code = <<-CODE
      if Object
        println("yes")
      end
      if Pair.new(1, 2)
        println("yes")
      end
      CODE
      $stdout.should_receive(:puts).with("yes").exactly(2)
      interpreter.eval(code)
    end

    it "should fallback to else statements" do
      code = <<-CODE
      if no
        println("no")
      else
        println("yes")
      end
      CODE
      $stdout.should_receive(:puts).with("yes")
      interpreter.eval(code)
    end

    it "should use elsifs properly" do
      code = <<-CODE
      if no
        println("no")
      elsif yes
        println("yes")
      end
      CODE
      $stdout.should_receive(:puts).with("yes")
      interpreter.eval(code)
    end

    it "should fallback to chained elsifs" do
      code = <<-CODE
      if no
        println("no")
      elsif nil
        println("no")
      elsif yes
        println("yes")
      end
      CODE
      $stdout.should_receive(:puts).with("yes")
      interpreter.eval(code)
    end
  end

  describe "returns" do
    it "should be implicit" do
      code = <<-CODE
      msg do
        "Message"
      end
      msg()
      CODE
      ret = interpreter.eval(code)
      ret.ruby_value.should eq("Message")
    end

    it "should obey explicit" do
      code = <<-CODE
      msg do
        return "first"
        "second"
      end
      msg()
      CODE
      ret = interpreter.eval(code)
      ret.ruby_value.should eq("first")
    end

    it "should return nested implicitly" do
      code = <<-CODE
      msg do |val|
        if val
          "first"
        else
          "second"
        end
      end
      msg(on)
      CODE
      ret = interpreter.eval(code)
      ret.ruby_value.should eq("first")
    end

    it "should obey nested" do
      code = <<-CODE
      msg do |val|
        if val
          return "first"
        end
        "second"
      end
      msg(yes)
      CODE
      ret = interpreter.eval(code)
      ret.ruby_value.should eq("first")
    end

    it "should work within a loop" do
      code = <<-CODE
      get do |i|
        n = 0
        while n < 10
          if n is i
            return n
          end
          n += 1
        end
        nil
      end
      println(get(6))
      CODE
      $stdout.should_receive(:puts).with("6")
      interpreter.eval(code)
    end
  end

  describe "while" do
    it "should function" do
      code = <<-CODE
      i = 0
      sum = 0
      while i < 10
        sum += i
        i += 1
      end
      println(sum)
      CODE
      $stdout.should_receive(:puts).with("45")
      interpreter.eval(code)
    end

    it "should skip execution on next nodes" do
      code = <<-CODE
      i = 0
      sum = 0
      while i < 10
        if i is 1
          i += 1
          next
        end
        sum += i
        i += 1
      end
      println(sum)
      CODE
      $stdout.should_receive(:puts).with("44")
      interpreter.eval(code)
    end
  end

  describe "namespaces" do
    it "should be interpreted" do
      code = <<-CODE
      namespace SomeName
      end
      CODE
      -> { interpreter.eval(code) }.should_not raise_error
    end

    it "should contain definitions in it's own scope" do
      code = <<-CODE
      namespace SomeName
        Message = "Hello, World"
      end
      println(Message)
      CODE
      $stdout.should_receive(:puts).with("nil")
      interpreter.eval(code)
    end

    it "should allow access with qualifiers" do
      code = <<-CODE
      namespace SomeName
        class Greeter
          property greeting
          init do |@greeting| end
          greet do |name|
            "%@greeting, %name"
          end
        end
      end
      a = SomeName::Greeter.new("Hello")
      println(a.greet("World"))
      CODE
      $stdout.should_receive(:puts).with("Hello, World")
      -> { interpreter.eval(code) }.should_not raise_error
    end

    it "should allow access to root namespace" do
      code = <<-CODE
      Message = "Hello, World!"
      namespace Something
        println(::Message)
      end
      CODE
      $stdout.should_receive(:puts).with("Hello, World!")
      -> { interpreter.eval(code) }.should_not raise_error
    end

    it "should allow namespaced definition" do
      code = <<-CODE
      Message = "Hello, World!"
      namespace Spanish
        Message = "Hola, Mundo!"
      end
      println(Message)
      println(::Message)
      println(Spanish::Message)
      CODE
      $stdout.should_receive(:puts).twice.with("Hello, World!")
      $stdout.should_receive(:puts).with("Hola, Mundo!")
      -> { interpreter.eval(code) }.should_not raise_error
    end
  end

  describe "lambdas" do
    it "should be interpreted" do
      code = <<-CODE
      lmb = -> { |msg| println(msg) }
      lmb.call("Hello, World")
      CODE
      $stdout.should_receive(:puts).with("Hello, World")
      interpreter.eval(code)
    end

    it "should be usable from a method" do
      code = <<-CODE
      add_by_lambda do |a, b, lambda|
        if lambda?
          lambda.call(a, b)
        else
          0
        end
      end
      result = add_by_lambda(1, 2) -> { |a, b| a + b }
      println(result)
      CODE
      $stdout.should_receive(:puts).with("3")
      interpreter.eval(code)
    end
  end

  describe "EleetScript core" do
    it "should have a working Pair class" do
      code = <<-CODE
      print_pair do |pair|
        println(pair.key)
        println(pair.value)
      end
      p = Pair.new("Hello", "World")
      print_pair(p)
      p.key = "Hola"
      p.value = "Mundo"
      print_pair(p)
      CODE
      $stdout.should_receive(:puts).with("Hello")
      $stdout.should_receive(:puts).with("World")
      $stdout.should_receive(:puts).with("Hola")
      $stdout.should_receive(:puts).with("Mundo")
      interpreter.eval(code)
    end

    it "should have a working kind_of? method" do
      code = <<-CODE
      println("Hello".kind_of?(String))
      p = Pair.new(1, 2)
      println(p.kind_of?(Pair))
      println("Hello".kind_of?(Pair))
      CODE
      $stdout.should_receive(:puts).with("true").twice
      $stdout.should_receive(:puts).with("false")
      interpreter.eval(code)
    end

    describe "List class" do
      it "should work" do
        code = <<-CODE
        list = ["Hello", "msg" => "World"]
        list2 = List.new("Hola", "msg" => "Mundo")
        println(list[0])
        println(list["msg"])
        println(list2[0])
        println(list2["msg"])
        list["msg"] = "Konnichiwa"
        println(list["msg"])
        CODE
        $stdout.should_receive(:puts).with("Hello")
        $stdout.should_receive(:puts).with("World")
        $stdout.should_receive(:puts).with("Hola")
        $stdout.should_receive(:puts).with("Mundo")
        $stdout.should_receive(:puts).with("Konnichiwa")
        interpreter.eval(code)
      end

      it "should allow pushing/popping" do
        code = <<-CODE
        l = []
        l.push(10)
        l.push(8)
        println(l[0] + l[1])
        CODE
        $stdout.should_receive(:puts).with("18")
        interpreter.eval(code)
      end

      it "should use operators overloads" do
        code = <<-CODE
        l = []
        l < 10
        l < 20
        println(l[0] + l[1])
        CODE
        $stdout.should_receive(:puts).with("30")
        interpreter.eval(code)
      end

      it "should allow merge operations" do
        code = <<-CODE
        l1 = [1, 2, 10 => "What"]
        l2 = [3, 4, "msg" => "Hello"]
        l1.merge!(l2)
        println(l1)
        CODE
        $stdout.should_receive(:puts).with("[1, 2, 3, 4, 10=>\"What\", \"msg\"=>\"Hello\"]")
        interpreter.eval(code)
      end

      it "should use + method" do
        code = <<-CODE
        l1 = [1, 2]
        l2 = [3, 4]
        l1 + l2
        println(l1)
        CODE
        $stdout.should_receive(:puts).with("[1, 2, 3, 4]")
        interpreter.eval(code)
      end

      it "should have a working each method" do
        code = <<-CODE
        l = [1, 2, "three" => 3]
        l.each -> { |value, key|
          println("%key => %value")
        }
        CODE
        $stdout.should_receive(:puts).with("0 => 1")
        $stdout.should_receive(:puts).with("1 => 2")
        $stdout.should_receive(:puts).with("three => 3")
        interpreter.eval(code)
      end

      it "should have an inject function" do
        code = <<-CODE
        l = [1, 2, 3]
        k = ["one" => 1, "two" => 2, "three" => 3]
        l_sum = l.inject(0) -> { |sum, value|
          sum + value
        }
        println(l_sum)
        key_list = k.inject([]) -> { |list, value, key|
          list < key
          list
        }
        println(key_list)
        CODE
        $stdout.should_receive(:puts).with("6")
        $stdout.should_receive(:puts).with("[\"one\", \"two\", \"three\"]")
        interpreter.eval(code)
      end

      it "should have a map function" do
        code = <<-CODE
        class Person
          property fname lname
          init do |@fname, @lname| end
        end
        people = [
          Person.new("Brandon", "Buck"),
          Person.new("Kim", "Buck"),
          Person.new("Dillon", "Curry")
        ]
        fnames = people.map -> { |item| item.fname }
        println(fnames)
        CODE
        $stdout.should_receive(:puts).with("[\"Brandon\", \"Kim\", \"Dillon\"]")
        interpreter.eval(code)
      end
    end
  end
end