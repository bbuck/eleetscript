require "engine/engine"

class BaseTest
  def one; 1; end
  def two; 2; end
end

class BaseLockTest < BaseTest
  class << self
    def set_lock_return(value)
      @lock_return = value
    end

    def lock_return
      @lock_return
    end
  end

  def eleetscript_lock_methods
    self.class.lock_return
  end
end

class LockSpecificTest < BaseLockTest
  set_lock_return [:two]
end

class LockAllTest < BaseLockTest
  set_lock_return :all
end

class LockNoneTest < BaseLockTest
  set_lock_return :none
end

class BaseAllowTest < BaseTest
  class << self
    def set_allow_return(value)
      @allow_return = value
    end

    def allow_return
      @allow_return
    end
  end

  def eleetscript_allow_methods
    self.class.allow_return
  end
end

class AllowSpecificTest < BaseAllowTest
  set_allow_return [:one]
end

class AllowAllTest < BaseAllowTest
  set_allow_return :all
end

class AllowNoneTest < BaseAllowTest
  set_allow_return :none
end

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

    it "should properly access namespaced constants from core classes" do
      code = <<-ES
      MSG = "Hello, World"
      test do MSG end
      ES
      engine.evaluate(code)
      engine.call(:test).should eq("Hello, World")
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

    describe "method locks and allows" do
      describe "method locks" do
        describe "manual locks" do
          before { engine.set("a", BaseTest.new, lock: :two) }

          it "should allow me to set them" do
            -> { engine.set("a", BaseTest.new, lock: :two) }.should_not raise_error
          end

          it "should allow non-locked methods" do
            engine.evaluate("a.one").should eq(1)
          end

          it "should lock those methods" do
            engine.evaluate("a.two").should be_nil
          end

          it "should be circumventable" do
            engine.evaluate("a.class_ref.new.two").should eq(2)
          end
        end

        describe "class defined locks" do
          describe "blacklisting methods specifically" do
            before { engine["a"] = LockSpecificTest.new }

            it "should allow non-locked methods" do
              engine.evaluate("a.one").should eq(1)
            end

            it "should lock the method" do
              engine.evaluate("a.two").should be_nil
            end

            it "should not be circumventable" do
              engine.evaluate("a.class_ref.new.two").should be_nil
            end
          end

          describe "locking all methods" do
            before { engine["a"] = LockAllTest.new }

            it "should not allow any method" do
              engine.evaluate("a.one").should be_nil
              engine.evaluate("a.two").should be_nil
            end

            it "should not be circumventable" do
              engine.evaluate("a.class_ref.new.one").should be_nil
            end
          end

          describe "locking no methods" do
            before { engine["a"] = LockNoneTest.new }

            it "should allow all methods" do
              engine.evaluate("a.one").should eq(1)
              engine.evaluate("a.two").should eq(2)
            end
          end
        end
      end

      describe "method allows" do
        describe "manual allows" do
          before { engine.set("a", BaseTest.new, allow: :one) }

          it "should allow me to set them" do
            -> { engine.set("a", BaseTest.new, allow: :one) }.should_not raise_error
          end

          it "should allow allowed methods" do
            engine.evaluate("a.one").should eq(1)
          end

          it "should lock non-allowed methods" do
            engine.evaluate("a.two").should be_nil
          end

          it "should not circumventable" do
            engine.evaluate("a.class_ref.new.two").should be_nil
          end
        end

        describe "class defined allows" do
          describe "whitelisting methods specifically" do
            before { engine["a"] = AllowSpecificTest.new }

            it "should allow allowed methods" do
              engine.evaluate("a.one").should eq(1)
            end

            it "should lock non-allowed methods" do
              engine.evaluate("a.two").should be_nil
            end

            it "should not be circumventable" do
              engine.evaluate("a.class_ref.new.two").should be_nil
            end
          end

          describe "allowing all methods" do
            before { engine["a"] = AllowAllTest.new }

            it "should allow any method" do
              engine.evaluate("a.one").should eq(1)
              engine.evaluate("a.two").should eq(2)
            end
          end

          describe "allowing no methods" do
            before { engine["a"] = AllowNoneTest.new }

            it "should allow no methods" do
              engine.evaluate("a.one").should be_nil
              engine.evaluate("a.two").should be_nil
            end

            it "should not be circumventable" do
              engine.evaluate("a.class_ref.new.one").should be_nil
            end
          end
        end
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

    it "should properly access namespaced constants from core classes" do
      code = <<-ES
      namespace Test
        MSG = "Hello, World"
        test do MSG end
      end
      ES
      engine.evaluate(code)
      engine.call("Test::test").should eq("Hello, World")
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