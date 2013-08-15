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