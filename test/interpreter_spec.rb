require "lang/interpreter"

describe "Cuby::Interpreter" do
  let(:interpreter) { CB::Interpreter.new }

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
            if n == i
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
          if i == 1
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
  end

  describe "Cuby core" do
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

    it "should have a working List class" do
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
  end
end