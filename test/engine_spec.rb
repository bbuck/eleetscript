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
      expect(-> { ES::BaseEngine.new }).to raise_error
    end
  end

#  describe "EleetScript::SharedEngine" do
  shared_examples_for 'EleetScript engine' do
    let(:engine) { ES::SharedEngine.new }

    it "should execute code" do
      expect(engine.evaluate("10 + 10")).to eq(20)
    end

    it "should store values" do
      engine.evaluate("a = 10 + 10")
      expect(engine["a"]).to eq(20)
    end

    it "should have it's own context" do
      o_engine = ES::SharedEngine.new
      engine.evaluate("a = 10 + 10")
      expect(o_engine["a"]).to be_nil
      expect(engine["a"]).to eq(20)
    end

    it "should allow access to EleetScript objects" do
      expect(engine["true"]).to eq(true)
    end

    it "should properly access namespaced constants from core classes" do
      code = <<-ES
      MSG = "Hello, World"
      test do MSG end
      ES
      engine.evaluate(code)
      expect(engine.call(:test)).to eq("Hello, World")
    end

    describe "sharing core memory" do
      it "should succesfully add methods to defined classes" do
        code = <<-ES
        class ::String
          test_fn do
            true
          end
        end
        ES
        expect(engine.evaluate(code)).to_not eq(false)
      end

      it "should be able to access added methods" do
        engine2 = ES::SharedEngine.new
        expect(engine2.evaluate("\"code\".test_fn")).to eq(true)
      end
    end

    describe "object translation" do
      it "should pull strings out as ruby strings" do
        engine.evaluate("a = \"A String\"")
        expect(engine["a"].class).to eq(String)
      end

      it "should pull out symbols" do
        engine.evaluate("a = :some_symbol")
        expect(engine["a"].class).to eq(Symbol)
      end

      it "should pass in symbols" do
        engine["a"] = :some_other_symbol
        expect(engine.evaluate(":some_other_symbol is a")).to eq(true)
      end
    end

    describe "object wrappers" do
      it "should be provided for EleetScript objects" do
        eslist = engine["List"]
        expect(eslist.class_name).to eq("List")
      end

      it "should be usable like a class" do
        eslist = engine["List"]
        list = eslist.new(1, 2)
        list < 3
        expect(list.to_string).to eq("[1, 2, 3]")
      end
    end

    describe "method locks and allows" do
      describe "method locks" do
        describe "manual locks" do
          before { engine.set("a", BaseTest.new, lock: :two) }

          it "should allow me to set them" do
            expect(-> { engine.set("a", BaseTest.new, lock: :two) }).to_not raise_error
          end

          it "should allow non-locked methods" do
            expect(engine.evaluate("a.one")).to eq(1)
          end

          it "should lock those methods" do
            expect(engine.evaluate("a.two")).to be_nil
          end

          it "should be circumventable" do
            expect(engine.evaluate("a.class_ref.new.two")).to eq(2)
          end
        end

        describe "class defined locks" do
          describe "blacklisting methods specifically" do
            before { engine["a"] = LockSpecificTest.new }

            it "should allow non-locked methods" do
              expect(engine.evaluate("a.one")).to eq(1)
            end

            it "should lock the method" do
              expect(engine.evaluate("a.two")).to be_nil
            end

            it "should not be circumventable" do
              expect(engine.evaluate("a.class_ref.new.two")).to be_nil
            end
          end

          describe "locking all methods" do
            before { engine["a"] = LockAllTest.new }

            it "should not allow any method" do
              expect(engine.evaluate("a.one")).to be_nil
              expect(engine.evaluate("a.two")).to be_nil
            end

            it "should not be circumventable" do
              expect(engine.evaluate("a.class_ref.new.one")).to be_nil
            end
          end

          describe "locking no methods" do
            before { engine["a"] = LockNoneTest.new }

            it "should allow all methods" do
              expect(engine.evaluate("a.one")).to eq(1)
              expect(engine.evaluate("a.two")).to eq(2)
            end
          end
        end
      end

      describe "method allows" do
        describe "manual allows" do
          before { engine.set("a", BaseTest.new, allow: :one) }

          it "should allow me to set them" do
            expect(-> { engine.set("a", BaseTest.new, allow: :one) }).to_not raise_error
          end

          it "should allow allowed methods" do
            expect(engine.evaluate("a.one")).to eq(1)
          end

          it "should lock non-allowed methods" do
            expect(engine.evaluate("a.two")).to be_nil
          end

          it "should not circumventable" do
            expect(engine.evaluate("a.class_ref.new.two")).to be_nil
          end
        end

        describe "class defined allows" do
          describe "whitelisting methods specifically" do
            before { engine["a"] = AllowSpecificTest.new }

            it "should allow allowed methods" do
              expect(engine.evaluate("a.one")).to eq(1)
            end

            it "should lock non-allowed methods" do
              expect(engine.evaluate("a.two")).to be_nil
            end

            it "should not be circumventable" do
              expect(engine.evaluate("a.class_ref.new.two")).to be_nil
            end
          end

          describe "allowing all methods" do
            before { engine["a"] = AllowAllTest.new }

            it "should allow any method" do
              expect(engine.evaluate("a.one")).to eq(1)
              expect(engine.evaluate("a.two")).to eq(2)
            end
          end

          describe "allowing no methods" do
            before { engine["a"] = AllowNoneTest.new }

            it "should allow no methods" do
              expect(engine.evaluate("a.one")).to be_nil
              expect(engine.evaluate("a.two")).to be_nil
            end

            it "should not be circumventable" do
              expect(engine.evaluate("a.class_ref.new.one")).to be_nil
            end
          end
        end
      end
    end
  end

  describe "EleetScript::StandaloneEngine" do
    let(:engine_class) { EleetScript::StandaloneEngine }
    let(:engine) { engine_class.new }

    include_examples 'EleetScript engine'
  end

  describe "EleetScript::SharedEngine" do
    let(:engine_class) { EleetScript::SharedEngine }
    let(:engine) { engine_class.new }

    include_examples 'EleetScript engine'
  end
end
