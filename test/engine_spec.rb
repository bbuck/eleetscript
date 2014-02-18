require "engine/engine"

describe "EleetScript::Engine" do
  describe "EleetScript::BaseEngine" do
    it "should not be instantiable" do
      -> { ES::BaseEngine.new }.should raise_error
    end
  end

  describe "EleetScript::SharedEngine" do
    let(:engine) { ES::SharedEngine.new }

    it "should execute code" do
      engine.evaluate("10 + 10").should eq(20)
    end

    it "should store values" do
      engine.evaluate("a = 10 + 10")
      engine["a"].should eq(20)
    end

    it "should have it's own context" do
      o_engine = ES::SharedEngine.new
      engine.evaluate("a = 10 + 10")
      o_engine["a"].should eq(nil)
      engine["a"].should eq(20)
    end

    it "should allow access to EleetScript objects" do
      t = engine["true"]
      t.should be_true
    end

    describe "sharing core memory" do
      it "should succesfully add methods to defined classes" do
        code = <<-ES
        class String
          test_fn do
            true
          end
        end
        ES
        engine.evaluate(code).should_not be_false
      end

      it "should be able to access added methods" do
        engine2 = ES::SharedEngine.new
        engine2.evaluate("\"code\".test_fn").should be_true
      end
    end

    describe "object translation" do
      it "should pull strings out as ruby strings" do
        engine.evaluate("a = \"A String\"")
        engine["a"].class.should eq(String)
      end

      it "should pull out symbols" do
        engine.evaluate("a = :some_symbol")
        engine["a"].class.should eq(Symbol)
      end

      it "should pass in symbols" do
        engine["a"] = :some_other_symbol
        engine.evaluate(":some_other_symbol is a")
      end
    end

    describe "object wrappers" do
      it "should be provided for EleetScript objects" do
        eslist = engine["List"]
        eslist.class_name.should eq("List")
      end

      it "should be usable like a class" do
        eslist = engine["List"]
        list = eslist.new(1, 2)
        list < 3
        list.to_string.should eq("[1, 2, 3]")
      end
    end
  end

  describe "EleetScript::StandaloneEngine" do
    let(:engine) { ES::StandaloneEngine.new }

    it "should execute code" do
      engine.evaluate("10 + 10").should eq(20)
    end

    it "should store values" do
      engine.evaluate("a = 10 + 10")
      engine["a"].should eq(20)
    end

    it "should have it's own context" do
      o_engine = ES::SharedEngine.new
      engine.evaluate("a = 10 + 10")
      o_engine["a"].should eq(nil)
      engine["a"].should eq(20)
    end

    it "should allow access to EleetScript objects" do
      t = engine["true"]
      t.should be_true
    end

    describe "sharing core memory" do
      it "should succesfully add methods to defined classes" do
        code = <<-ES
        class String
          test_fn do
            true
          end
        end
        ES
        engine.evaluate(code).should_not be_false
      end

      it "should be unable to access added methods" do
        engine2 = ES::StandaloneEngine.new
        engine2.evaluate("\"code\".test_fn").should be_nil
      end
    end

    describe "object wrappers" do
      it "should be provided for EleetScript objects" do
        eslist = engine["List"]
        eslist.class_name.should eq("List")
      end

      it "should be usable like a class" do
        eslist = engine["List"]
        list = eslist.new(1, 2)
        list < 3
        list.to_string.should eq("[1, 2, 3]")
      end
    end
  end
end