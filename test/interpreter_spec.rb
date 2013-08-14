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

    # describe "methods" do
    #   it "should receive compiled arguments" do
    #     code = <<-CODE
    #     test do |a|
    #       println(a)
    #       println(arguments)
    #     end
    #     test()
    #     CODE
    #     $stdout.should_receive(:puts).twice
    #     interpreter.eval(code)
    #   end
    # end
  end

  describe "classes" do
    it "should interpret class definitions" do
      code = <<-CODE
      class Greeter
        init do |@greeting| end
        greet do |name|
          "\#{@greeting} \#{name}"
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
          println("\#{@greeting}, \#{name}")
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
          println("\#{@greeting}, \#{name}")
        end
      end
      g = Greeter.create("Hello")
      g.greet("World")
      CODE
      $stdout.should_receive(:puts).with("Hello, World")
      interpreter.eval(code)
    end
  end
end