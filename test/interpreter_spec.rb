require "lang/interpreter"

describe "Cuby::Interpreter" do
  let(:interpreter) { CB::Interpreter.new }

  it "should interpret simple code" do
    $stdout.should_receive(:puts).with("Hello, World")
    code = "println(\"Hello, World\")"
    interpreter.eval(code)
  end

  it "should handle assigning and reading local variables" do
    $stdout.should_receive(:puts).with("Hello, World")
    code = <<-CODE
    msg = "Hello, World"
    println(msg)
    CODE
    interpreter.eval(code)
  end

  it "should call local methods if local vars aren't defined" do
    $stdout.should_receive(:puts).with("Hello, World")
    code = <<-CODE
    msg do
      "Hello, World"
    end
    println(msg)
    CODE
    interpreter.eval(code)
  end
end